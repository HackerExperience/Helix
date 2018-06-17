defmodule Helix.Event.PublicationHandler do

  import HELL.Macros

  alias HELL.Utils
  alias Helix.Event.Publishable
  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState

  @type channel_account_id :: Account.id | Entity.id

  @doc """
  Handler responsible for guiding the event through the Publishable flow. It
  will query `Publishable.whom_to_publish` to know which channels should receive
  the event. Then, this event is broadcasted to each channel.
  """
  def publication_handler(event) do
    if Publishable.impl_for(event) do
      event = Publishable.Flow.add_event_identifier(event)

      event
      |> Publishable.whom_to_publish()
      |> channel_mapper()
      |> Enum.each(&(Helix.Endpoint.broadcast(&1, "event", event)))
    end
  end

  docp """
  Interprets the return `Publishable.whom_to_publish/1` format, returning a list
  of valid channel topics/names.
  """
  @spec channel_mapper(Publishable.whom_to_publish) ::
    channels :: [String.t]
  defp channel_mapper(whom_to_publish, acc \\ [])
  defp channel_mapper(publish = %{server: servers}, acc) do
    acc =
      servers
      |> Utils.ensure_list()
      |> Enum.uniq()
      |> get_server_channels()
      |> List.flatten()
      |> Kernel.++(acc)

    channel_mapper(Map.delete(publish, :server), acc)
  end

  defp channel_mapper(publish = %{account: accounts}, acc) do
    acc =
      accounts
      |> Utils.ensure_list()
      |> Enum.uniq()
      |> get_account_channels()
      |> List.flatten()
      |> Kernel.++(acc)

    channel_mapper(Map.delete(publish, :account), acc)
  end

  defp channel_mapper(%{}, acc),
    do: acc

  @spec get_server_channels([Server.id] | Server.id) ::
    channels :: [String.t]
  defp get_server_channels(servers) when is_list(servers),
    do: Enum.map(servers, &get_server_channels/1)
  defp get_server_channels(server_id) do
    open_channels = ServerWebsocketChannelState.list_open_channels(server_id)

    # Returns remote channels (joined using nips)
    nips =
      if open_channels do
        Enum.map(open_channels, fn channel ->
          "server:"
          |> concat(channel.network_id)
          |> concat("@")
          |> concat(channel.ip)
          |> concat("#")
          |> concat(channel.counter)
        end)
      else
        []
      end

    # Also include the server ID as channel (used on local (gateway) join)
    nips ++ ["server:" <> to_string(server_id)]
  end

  @spec get_account_channels([channel_account_id] | channel_account_id) ::
    channels :: [String.t]
  defp get_account_channels(accounts) when is_list(accounts),
    do: Enum.map(accounts, &get_account_channels/1)
  defp get_account_channels(account_id),
    do: ["account:" <> to_string(account_id)]

  defp concat(a, b),
    do: a <> to_string(b)
end
