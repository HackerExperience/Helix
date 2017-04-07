defmodule Helix.Router.Socket.Public do

  use Phoenix.Socket

  channel "account", Helix.Account.WS.Channel.Public.Account

  def connect(_, socket),
    do: {:ok, socket}
  def id(_),
    do: "guest"
end
