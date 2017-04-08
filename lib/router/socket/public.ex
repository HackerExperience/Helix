defmodule Helix.Router.Socket.Public do

  use Phoenix.Socket

  channel "requests", Helix.Router.Channel.PublicRequests

  def connect(_, socket),
    do: {:ok, socket}

  def id(_),
    do: "guest"
end
