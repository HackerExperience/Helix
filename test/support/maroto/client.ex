defmodule Helix.Maroto.ClientTools do

  alias Helix.Event
  alias Helix.Event.Notificable
  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server

  alias Helix.Test.Account.Helper, as: AccountHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  defmacro __using(_) do
    quote do

      import Helix.Maroto.Client

    end
  end

  # (`trash` is a workaround to let us group these functions as we want)
  def testcast(topic, event, opts_or_name \\ [], opts_or_trash \\ [])

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
    |> Enum.map(&(broadcast(build_topic(&1), payload)))
  end

  defp broadcast_all("server", payload) do
    ServerHelper.get_all()
    |> Enum.map(&(broadcast(build_topic(&1), payload)))
  end

  # Builders

  defp build_topic(server = %Server{}),
    do: "server:" <> to_string(server.server_id)
  defp build_topic(account = %Account{}),
    do: "account:" <> to_string(account.account_id)
  defp build_topic(entity = %Entity{}),
    do: "account:" <> to_string(entity.entity_id)

  defp build_event(event = %_{__meta__: _}, _opts) do
    {:ok, payload} = Notificable.generate_payload(event, %{})

    %{
      data: payload,
      event: Notificable.get_event_name(event),
      meta: Event.Meta.render(event)
    }
  end

  defp build_event(payload = %{}, name, _opts) do
    %{
      data: payload,
      event: to_string(name),
      meta: %{}
    }
  end
end
