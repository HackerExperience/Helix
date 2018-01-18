defmodule Helix.Maroto.ClientTools do

  alias Helix.Event
  alias Helix.Event.Notificable
  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Channel.Interceptor
  alias Helix.Test.Server.Helper, as: ServerHelper

  defmacro __using(_) do
    quote do

      import Helix.Maroto.Client

    end
  end

  @doc """
  Intercepts `endpoint` so, the first time a request goes through, its answer
  will be `{status, payload}`, where `status` is either `:ok` or `:error`, and
  payload is a map. After the first intercept, upcoming calls to the same
  endpoint will behave as usual.

  NOTE: The actual payload sent will be wrapped into the format required by the
  Client, so it would probably reply something like:

    %{data: `payload`, meta: %{request_id: nil}}
  """
  def intercept_once(endpoint, response = {status, payload}) do
    unless status in [:ok, :error],
      do: raise "Invalid status #{status}. Use either `:ok` or `:error`"

    unless is_map(payload),
      do: raise "Payload must be a map, got #{inspect payload}"

    Interceptor.intercept_once(endpoint, response)
  end

  @doc """
  Intercepts `endpoint`, answering `{status, payload}`, where `status` is either
  `:ok` or `:error`, and payload is a map. It will keep intercepting until
  `stop_intercept` is called.

  NOTE: The actual payload sent will be wrapped into the format required by the
  Client, so it would probably reply something like:

  %{data: `payload`, meta: %{request_id: nil}}
  """
  def intercept_forever(endpoint, response = {status, payload}) do
    unless status in [:ok, :error],
      do: raise "Invalid status #{status}. Use either `:ok` or `:error`"

    unless is_map(payload),
      do: raise "Payload must be a map, got #{inspect payload}"

    Interceptor.intercept_forever(endpoint, response)
  end

  @doc """
  Stops an on-going intercept defined with `intercept_forever/2`
  """
  def stop_intercept(endpoint),
    do: Interceptor.stop_intercept(endpoint)

  @doc """
  Broadcasts an event to the Client.

  # Channels:

  The first parameter of `testcast/4` is used to identify which channel should
  receive the broadcast.

  ## Account

  - "account": Sends the event to all registered accounts
  - "account:<ID>": Sends the event to the specific topic
  - Account.t: Sends the event to the given account
  - Entity.t: Sends the event to the given entity (entity == account here)

  ## Server

  - "server": Sends the event to all registered servers
  - "server:<ID>": Sends the event to the specific server (identified by ID)
  - "server:<N:IP>": Sends the event to the specific server (identified by NIP)
  - Server.t: Sends the event to the given server

  # Events

  The remaining params are used to identify which event should be broadcasted.

  ## Event.t

  If you pass a valid Event.t (created from EventSetup.*) I'll do all the
  hard work to figure out the event payload as it would be used by Helix and
  send you back. This is the most reliable way to use `testcast`.

  NOTE: In order for this to work, the received Event.t must implement the
  Notificable protocol (if it doesn't, you'd never receive the event anyway)

  ## Raw payload

  If you don't have a valid Event.t laying around, you can specify the raw
  payload you should receive, as well as the expected event name. This is
  especially useful if you want to test an event that does not exist on Helix.

  NOTE: The actual event received by the Client will be wrapped into the
  expected format, so it would become something like:

    %{data: `payload`, meta: %{request_id: _, event_id: _, process_id: _}}

  # Opts

  Regardless of the event you've passed as parameter (Event.t or raw payload),
  you may specify some metadata.

  - request_id: Set the `request_id` value within `meta`
  - event_id: Set the `event_id` value within `meta`
  - process_id: Set the `process_id` value within `meta`

  Missing something? Let me know!
  """
  # (`trash` is a workaround to let us group these functions as we want)
  def testcast(topic, event_or_payload, opts_or_name \\ [], opts_or_trash \\ [])

  # Account channel

  def testcast("account", event = %_{__meta__: _}, opts, _),
    do: broadcast_all("account", build_event(event, opts))
  def testcast("account", payload = %{}, name, opts),
    do: broadcast_all("account", build_event(payload, name, opts))
  def testcast(account = %Account{}, event = %_{__meta__: _}, opts, _),
    do: broadcast(build_topic(account), build_event(event, opts))
  def testcast(entity = %Entity{}, event = %_{__meta__: _}, opts, _),
    do: broadcast(build_topic(entity), build_event(event, opts))
  def testcast(account = %Account{}, payload = %{}, name, opts),
    do: broadcast(build_topic(account), build_event(payload, name, opts))
  def testcast(entity = %Entity{}, payload = %{}, name, opts),
    do: broadcast(build_topic(entity), build_event(payload, name, opts))
  def testcast(topic = "account:" <> _, event = %_{__meta__: _}, opts, _),
    do: broadcast(topic, build_event(event, opts))
  def testcast(topic = "account:" <> _, payload = %{}, name, opts),
    do: broadcast(topic, build_event(payload, name, opts))

  # Server channel

  def testcast("server", event = %_{__meta__: _}, opts, _),
    do: broadcast_all("server", build_event(event, opts))
  def testcast("server", payload = %{}, name, opts),
    do: broadcast_all("server", build_event(payload, name, opts))
  def testcast(server = %Server{}, event = %_{__meta__: _}, opts, _),
    do: broadcast(build_topic(server), build_event(event, opts))
  def testcast(server = %Server{}, payload = %{}, name, opts),
    do: broadcast(build_topic(server), build_event(payload, name, opts))
  def testcast(topic = "server:" <> _, event = %_{__meta__: _}, opts, _),
    do: broadcast(topic, build_event(event, opts))
  def testcast(topic = "server:" <> _, payload = %{}, name, opts),
    do: broadcast(topic, build_event(payload, name, opts))

  # Broadcasters

  defp broadcast(topic, payload) when not is_binary(topic),
    do: broadcast(to_string(topic), payload)
  defp broadcast(topic, payload) do
    Helix.Endpoint.broadcast(topic, "event_marote", payload)

    IO.puts "Broadcasted to #{topic} -- #{inspect payload}"
  end

  defp broadcast_all("account", payload) do
    AccountHelper.get_all()
    |> Enum.each(&(broadcast(build_topic(&1), payload)))
  end

  defp broadcast_all("server", payload) do
    all_servers = ServerHelper.get_all()

    # Broadcast to "server:<ID>"
    Enum.each(all_servers, &(broadcast(build_topic(&1), payload)))

    # Broadcast to "server:<network_id>@<ip>"
    all_servers
    |> Enum.map(&(ServerHelper.get_all_nips(&1)))
    |> Enum.each(fn nips ->
      Enum.each(nips, &(broadcast(build_topic(&1), payload)))
    end)
  end

  # Builders

  defp build_topic(server = %Server{}),
    do: "server:" <> to_string(server.server_id)
  defp build_topic(account = %Account{}),
    do: "account:" <> to_string(account.account_id)
  defp build_topic(entity = %Entity{}),
    do: "account:" <> to_string(entity.entity_id)
  defp build_topic(%{ip: ip, network_id: network_id}),
    do: "server:" <> to_string(network_id) <> "@" <> ip

  defp build_event(event = %_{__meta__: _}, opts) do
    {:ok, payload} = Notificable.generate_payload(event, %{})

    %{
      data: payload,
      event: Notificable.get_event_name(event),
      meta: Event.Meta.render(event)
    }
    |> merge_meta(opts)
  end

  defp build_event(payload = %{}, name, opts) do
    %{
      data: payload,
      event: to_string(name),
      meta: empty_meta()
    }
    |> merge_meta(opts)
  end

  defp empty_meta,
    do: Event.Meta.render(%{__meta__: nil})

  defp merge_meta(event = %{meta: meta}, opts) do
    request_id = Keyword.get(opts, :request_id, meta.request_id)
    event_id = Keyword.get(opts, :event_id, meta.event_id)
    process_id = Keyword.get(opts, :process_id, meta.process_id)

    new_meta =
      %{
        request_id: request_id,
        event_id: event_id,
        process_id: process_id,
      }

    %{event| meta: new_meta}
  end
end
