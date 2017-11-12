defmodule Helix.Client.Public.ClientTest do

  use Helix.Test.Case.Integration

  alias Helix.Entity.Model.Entity
  alias Helix.Client.Public.Client, as: ClientPublic

  alias Helix.Test.Client.Web1.Setup, as: Web1Setup

  describe "bootstrap/2" do
    test "web1 bootstrap" do
      {setup, _} = Web1Setup.setup()

      assert %{client: bootstrap} =
        ClientPublic.bootstrap(:web1, setup.entity_id)

      assert bootstrap.setup.pages == setup.pages
    end

    test "web1 bootstrap (empty)" do
      assert %{client: bootstrap} =
        ClientPublic.bootstrap(:web1, Entity.ID.generate())

      assert bootstrap.setup.pages == []
    end
  end

  describe "render_bootstrap/2" do
    test "web1 rbootstrap" do
      {setup, _} = Web1Setup.setup()

      bootstrap = ClientPublic.bootstrap(:web1, setup.entity_id)

      assert %{client: render_bootstrap} =
        ClientPublic.render_bootstrap(:web1, bootstrap)

      assert Enum.all?(render_bootstrap.setup.pages, &is_binary/1)
    end

    test "web1 rbootstrap (empty)" do
      bootstrap = ClientPublic.bootstrap(:web1, Entity.ID.generate())

      assert %{client: render_bootstrap} =
        ClientPublic.render_bootstrap(:web1, bootstrap)

      assert render_bootstrap.setup.pages == []
    end
  end
end
