defmodule Helix.Websocket.RequestsChannel do

  use Phoenix.Channel

  alias Helix.Account.Websocket.Routes, as: Account
  alias Helix.Network.Websocket.Routes, as: Network

  def join(_topic, _message, socket) do
    # God in the command
    {:ok, socket}
  end

  def handle_in("account.logout", _params, socket),
    do: Account.account_logout(socket)

  def handle_in("network.browse", params, socket),
    do: Network.browse_ip(socket, params)

  def handle_in(_, _, socket) do
    {:reply, :error, socket}
  end
end
