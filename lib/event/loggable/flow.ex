defmodule Helix.Event.Loggable.Flow do
  @moduledoc """
  LoggableFlow is responsible for guiding all events through the Loggable steps,
  as well as implementing helper methods to aid a smooth Log support.

  The main components are the `loggable` and `log` macros, which remove the
  boilerplate of the Loggable protocol implementation.

  The flow is quite simple: first, a log entry is generated. This log entry
  contains the `server_id` which that log should be saved at, the `entity_id`
  which generated the log, and the log `message` itself.

  This entry is generated at each Loggable event, using the Loggable protocol.
  Finally, guided through the LogEventHandler, the `save/1` function is called,
  which will persist the entries on the database and emit the corresponding
  `LogCreatedEvent` for each inserted log.

  For an implementation example, see `lib/software/event/file.ex`.
  """

  import HELL.Macros

  alias HELL.Macros.Utils, as: MacroUtils
  alias Helix.Event
  alias Helix.Event.Loggable.Utils, as: LoggableUtils
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Action.Log, as: LogAction

  @type log_entry ::
    {Server.id, Entity.id, log_msg}

  @type log_msg :: String.t

  @doc """
  Top-level macro for events wanting to implement the Loggable protocol.
  """
  defmacro loggable(do: block) do
    quote do

      defimpl Helix.Event.Loggable do
        @moduledoc false

        unquote(block)

        # Declaring the typespec for `generate/1` here, since the Event may
        # implement multiple `log/2` patterns, but they all share the same
        # signature
        @spec generate(unquote(__CALLER__.module).t) ::
          [Helix.Event.Loggable.Flow.log_entry]

        # Fallback
        def generate(_),
          do: []
      end

    end
  end

  @doc """
  Inserts the Loggable's `generate` functions. Multiple `log` macros may be
  defined, in which case the event will be pattern-matched against them.
  """
  defmacro log(query, do: block) do
    query = replace_module(query, __CALLER__.module)

    quote do

        def generate(unquote(query)) do
          unquote(block)
        end

    end
  end

  docp """
  This is probably my greatest gambiarra ("creative implementation") so far.

  It verifies if the caller used the %__MODULE__{} expression on the event being
  pattern-matched, and replaces it with the proper alias. The reason for this is
  that the generated macro won't play nicely with `__MODULE__`.

  If no event is being pattern-matched, or it isn't using `__MODULE__`, the
  query remains unchanged.

  This is the classic DO NOT TOUCH function. The good news is, if you do touch
  and mess everything up, Helix won't compile.
  """
  defp replace_module(query, caller) do
    caller = MacroUtils.remove_protocol_namespace(caller, Helix.Event.Loggable)

    {a, s, t} = query

    # Verifies whether it's a pattern match (`var = :something`)
    if a == := do
      try do

        # If the pattern below is valid, we are trying to match a named struct,
        # either with `var = %__MODULE__{}` or `var = %ModuleName{}`. If it's
        # the former, we "migrate" to the later format, using the `caller` name
        [e, {p1, p2, [r = {pattern, c, _}, p3]}] = t

        r =
          if pattern == :__MODULE__ do
            {:__aliases__, c, [caller]}
          else
            r
          end

        {a, s, [e, {p1, p2, [r, p3]}]}

      # Rescuing means the pattern being matched is something else, maybe a
      # plain map (`var = %{foo: :bar}`)
      rescue
        MatchError ->
          query
      end
    else
      query
    end
  end

  defdelegate get_file_name(file),
    to: LoggableUtils

  defdelegate get_ip(server_id, network_id),
    to: LoggableUtils

  defdelegate censor_ip(ip),
    to: LoggableUtils

  @spec build_entry(Server.id, Entity.id, log_msg) ::
    log_entry
  @doc """
  Returns data required to insert the log
  """
  def build_entry(server_id, entity_id, msg),
    do: {server_id, entity_id, msg}

  @spec save([log_entry] | log_entry) ::
    term
  @doc """
  Receives the list of generated entries, which is returned by each event
  that implements the Loggable protocol, and inserts them into the game
  database, emitting the relevant `LogCreatedEvent`
  """
  def save([]),
    do: :ok
  def save(log_entry = {_, _, _}),
    do: save([log_entry])
  def save(logs) do
    logs
    |> Enum.map(fn {server_id, entity_id, msg} ->
      {:ok, _, events} = LogAction.create(server_id, entity_id, msg)
      events
    end)
    |> List.flatten()
    |> Enum.each(&Event.emit/1)
  end
end
