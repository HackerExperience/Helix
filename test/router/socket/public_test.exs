defmodule Helix.Router.Socket.PublicTest do

  use ExUnit.Case, async: true

  alias Helix.Router.Socket.Public, as: Socket

  import Phoenix.ChannelTest

  @endpoint Helix.Endpoint

  test "socket is connectable by anyone" do
    assert {:ok, _} = connect(Socket, %{})
  end
end
