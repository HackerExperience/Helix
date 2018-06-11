defmodule Helix.Event.NotificationHandler do

  import HELL.Macros

  alias HELL.Utils
  alias Helix.Event.Notificable
  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.Bank.Model.BankAccount

  @type channel_account_id :: Account.id | Entity.id
  @type channel_bank_id :: {ATM.id, BankAccount.account}

  @doc """
  Handler responsible for guiding the event through the Notificable flow. It
  will query `Notificable.whom_to_notify` to know which channels should receive
  the event. Then, this event is broadcasted to each channel.
  """
  def notification_handler(event) do
    if Notificable.impl_for(event) do
      event = Notificable.Flow.add_event_identifier(event)

      event
      |> Notificable.whom_to_notify()
      |> channel_mapper()
      |> Enum.each(&(Helix.Endpoint.broadcast(&1, "event", event)))
    end
  end

  docp """
  Interprets the return `Notificable.whom_to_notify/1` format, returning a list
  of valid channel topics/names.
  """
  @spec channel_mapper(Notificable.whom_to_notify) ::
    channels :: [String.t]
  defp channel_mapper(whom_to_notify, acc \\ [])
  defp channel_mapper(notify = %{bank_acc: bank_accs}, acc) do
    acc =
      bank_accs
      |> Utils.ensure_list()
      |> Enum.uniq()
      |> get_bank_channels()
      |> List.flatten()
      |> Kernel.++(acc)

      channel_mapper(Map.delete(notify, :bank_acc), acc)
  end

  defp channel_mapper(notify = %{server: servers}, acc) do
    acc =
      servers
      |> Utils.ensure_list()
      |> Enum.uniq()
      |> get_server_channels()
      |> List.flatten()
      |> Kernel.++(acc)

    channel_mapper(Map.delete(notify, :server), acc)
  end

  defp channel_mapper(notify = %{account: accounts}, acc) do
    acc =
      accounts
      |> Utils.ensure_list()
      |> Enum.uniq()
      |> get_account_channels()
      |> List.flatten()
      |> Kernel.++(acc)

    channel_mapper(Map.delete(notify, :account), acc)
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

  @spec get_bank_channels([channel_bank_id] | channel_bank_id) ::
    channels :: [String.t]
  defp get_bank_channels(bank_accs) when is_list(bank_accs),
    do: Enum.map(bank_accs, &get_bank_channels/1)
  defp get_bank_channels({atm_id, account_number}),
    do: ["bank:" <> to_string(account_number) <> "@" <> to_string(atm_id)]

  defp concat(a, b),
    do: a <> to_string(b)
end
