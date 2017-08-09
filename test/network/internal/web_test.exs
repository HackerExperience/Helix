defmodule Helix.Network.Internal.WebTest do

  use Helix.Test.IntegrationCase

  alias Helix.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Network.Internal.Web, as: WebInternal

  describe "serve/2" do
    test "serves NPC pages correctly" do
      {_, ip} = NPCHelper.download_center()

      assert {:ok, page} = WebInternal.serve("::", ip)

      assert page.title
    end
  end
end
