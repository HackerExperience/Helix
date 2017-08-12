defmodule Helix.Network.Model.Web.PlayerTest do

  use ExUnit.Case, async: true

  alias Helix.Network.Model.Web.Player

  alias HELL.TestHelper.Random

  @max_content_size 2048

  describe "create_changeset/1" do
    test "restricts content size" do
      valid_string = Random.string(length: @max_content_size)
      invalid_string = Random.string(length: @max_content_size + 1)

      valid_params = %{ip: Random.ipv4(), content: valid_string}
      invalid_params = %{ip: Random.ipv4(), content: invalid_string}

      valid_cs = Player.create_changeset(valid_params)
      assert valid_cs.valid?

      invalid_cs = Player.create_changeset(invalid_params)
      refute invalid_cs.valid?
    end
  end
end
