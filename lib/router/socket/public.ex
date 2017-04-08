defmodule Helix.Router.Socket.Public do

  use Phoenix.Socket

  transport :websocket, Phoenix.Transports.WebSocket

  channel "requests", Helix.Router.Channel.PublicRequests

  def connect(_, socket),
    do: {:ok, socket}

  def id(_),
    do: "guest"
end
