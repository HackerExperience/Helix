defmodule Helix.Account.Websocket.Channel.Account do
  @moduledoc """
  Channel to notify an user of an action that affects them.
  """

  use Phoenix.Channel

  alias Helix.Websocket.Socket, as: Websocket

  alias Helix.Account.Websocket.Channel.Account.Join, as: AccountJoin
  alias Helix.Account.Websocket.Channel.Account.Requests.Bootstrap,
    as: BootstrapRequest

  def join(topic, _params, socket) do
    request = AccountJoin.new(topic)
    Websocket.handle_join(request, socket, &assign/3)
  end

  def handle_in("bootstrap", _params, socket) do
    request = BootstrapRequest.new()
    Websocket.handle_request(request, socket)
  end

  intercept ["event"]

  def handle_out("event", event, socket),
    do: Websocket.handle_event(event, socket, &push/3)
end
