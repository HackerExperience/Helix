defmodule Helix.Endpoint do

  use Phoenix.Endpoint, otp_app: :helix

  require Helix.Appsignal

  socket "/", Helix.Websocket

  plug Corsica,
    origins: Application.get_env(:helix, Helix.Endpoint)[:allowed_cors],
    allow_headers: ["content-type", "x-request-id"]

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
