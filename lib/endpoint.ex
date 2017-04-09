defmodule Helix.Endpoint do
  use Phoenix.Endpoint, otp_app: :helix

  socket "/", Helix.Websocket.Socket

  plug Plug.Static,
    at: "/",
    from: :helix,
    gzip: false,
    only: ~w(css fonts images js favicon.ico robots.txt)

  plug Plug.RequestId
  plug Plug.Logger

  plug Plug.Parsers,
    length: 2_000_000,
    read_timeout: 5_000,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Poison

  plug Helix.HTTP.Router
end
