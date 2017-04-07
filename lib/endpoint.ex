defmodule Helix.Endpoint do
  use Phoenix.Endpoint, otp_app: :helix

  socket "/public", Helix.Router.Socket.Public
  socket "/player", Helix.Router.Socket.Player
end
