defmodule Helix.Logger do
  @moduledoc """
  `Helix.Logger` is an abstraction over Elixir `Logger`. It considers the
  environment Helix is running on, and send the logs to the desired collector.

  On dev environment, it also broadcasts the message to the Logflix channel.
  """

  import HELL.Macros

  alias HELL.ClientUtils
  alias HELL.Utils

  defmacro __using__(_) do
    quote do

      import Helix.Logger

      require Logger

    end
  end

  @doc """
  Top-level macro for emitting an (internal) log.
  """
  defmacro log(event_type, identifier, opts \\ quote(do: [])) do
    event_type = to_string(event_type)

    relay = Keyword.get(opts, :relay, false)

    # Set the Timber context (used in `prod`) and return the context map too,
    # which is used in `dev` and `test`.
    relay_block =
      if relay do
        quote do
          account_id = unquote(relay).account_id |> to_string()
          request_id = unquote(relay).request_id
          topic = unquote(relay).topic
          method = unquote(relay).type

          # Workaround for the required - and validated - TimberHTTPContext
          method =
            case unquote(relay).type do
              :request ->
                "GET"

              :join ->
                "POST"
            end

          # TODO: Using custom context while timber-elixir#247 isn't fixed
          # https://github.com/timberio/timber-elixir/issues/247
          # #348 on Helix
          [id: account_id]
          |> Timber.add_context()

          [request_id: request_id, path: topic, method: method]
          |> Timber.add_context()

          %{
            account_id: account_id,
            request_id: request_id
          }
        end
      else
        quote do
          %{}
        end
      end

    params =
      if relay do
        quote(do: unquote(relay).params)
      else
        Keyword.get(opts, :params, "")
      end

    data = Keyword.get(opts, :data, %{})

    # Formats the custom `data`, if any, ensuring it is JSON-friendly (on `prod`
    # it is used by the Timber API, and on `dev` it's used on the Logflix API).
    event =
      if data == %{} do
        quote do
          %{}
        end
      else
        quote do
          formatted_data = Utils.stringify_map(unquote(data))
          |> Map.put(:params, unquote(params))

          %Timber.Events.CustomEvent{
            data: formatted_data,
            type: unquote(event_type) |> String.to_atom()
          }
        end
      end

    # Builds up the message. On `dev` the message itself has all context/event
    # data, since it will be logged to a file. On production it's all structured
    # so we don't need a fancy message.
    msg =
      if Mix.env == :prod do
        quote do
          "#{unquote(event_type)} - #{to_string(unquote(identifier))}"
        end
      else
        quote do
          context =
            unquote(relay)
            |> Map.from_struct()
            |> Utils.stringify_map()

          "#{unquote(event_type)} - #{to_string(unquote(identifier))} - "
          <> "#{inspect context}"
          <> "#{inspect unquote(event)}"
        end
      end

    # Specify log type/severity (:debug, :info, :warn, :error). Default is :info
    log_type = Keyword.get(opts, :type, :info)

    quote location: :keep do

      # Log emission is asynchronous
      hespawn fn ->
        context_data = unquote(relay_block)

        id = unquote(identifier) |> to_string()

        # Broadcast the channel to Logflix - only on dev/test.
        unless Mix.env == :prod do
          context_data = Map.put(context_data, :id, id)
          event = unquote(event) |> Map.delete(:__struct__)

          meta =
            %{}
            |> Map.put(:id, id)
            |> Map.merge(context_data)
            |> Map.merge(event)

          payload =
            %{}
            |> Map.put(:type, unquote(event_type))
            |> Map.put(:meta, meta)
            |> Map.put(:timestamp, ClientUtils.to_timestamp(DateTime.utc_now()))

          Helix.Endpoint.broadcast "logflix", "event",
            %{data: payload, event: "new_log"}
        end

        Logger.unquote(log_type)(
          fn -> {unquote(msg), event: unquote(event)} end
        )
      end

    end
  end
end
