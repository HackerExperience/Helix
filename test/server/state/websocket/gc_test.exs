defmodule Helix.Server.State.Websocket.GCTest do

  use ExUnit.Case, async: true

  alias Helix.Server.State.Websocket.Channel, as: ServerWebsocketChannelState
  alias Helix.Server.State.Websocket.GC, as: ServerWebsocketGC

  alias Helix.Test.Server.State.Helper, as: ServerStateHelper

  describe "ServerWebsocketGC" do
    test "it removes my trash every monday, wednesday and friday" do
      # Scenario: Two players logged at one different server each
      ServerWebsocketChannelState.join("e1", "s1", {"n", "ip1"}, 0)
      ServerWebsocketChannelState.join("e2", "s2", {"n", "ip1"}, 0)

      # We'll then remove `e1` and `e2` from `s1` and `s2`, respectively
      ServerWebsocketChannelState.leave("e1", "s1", {"n", "ip1"}, 0)
      ServerWebsocketChannelState.leave("e2", "s2", {"n", "ip1"}, 0)

      # It's still there, since it hasn't being GCed
      assert ServerStateHelper.lookup_server("s1")
      assert ServerStateHelper.lookup_server("s2")

      # We'll set GCTimer interval to 50ms & wait for it
      ServerWebsocketGC.set_interval(50)
      :timer.sleep(100)

      # It's gone
      refute ServerStateHelper.lookup_server("s1")
      refute ServerStateHelper.lookup_server("s2")
    end
  end
end
