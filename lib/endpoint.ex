defmodule Helix.Endpoint do
  use Phoenix.Endpoint, otp_app: :helix

  socket "/ws", Helix.Router.Socket.Public
  socket "/ws/player", Helix.Router.Socket.Player
end
