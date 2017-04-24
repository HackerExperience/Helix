defmodule Helix.Websocket.RequestsChannel do

  use Phoenix.Channel

  alias Helix.Account.Websocket.Routes, as: Account
  alias Helix.Server.Websocket.Routes, as: Server

  def join(_topic, _message, socket) do
    # God in the command
    {:ok, socket}
  end

  def handle_in("account.logout", _params, socket),
    do: Account.account_logout(socket)

  def handle_in("server.crack", params, socket),
    do: Server.server_crack(params, socket)

  def handle_in(_, _, socket) do
    {:reply, :error, socket}
  end
end
