defmodule Helix.Log.Model.LogTest do

  use ExUnit.Case, async: true

  alias Helix.Log.Model.Log

  @moduletag :unit

  describe "log creation" do
    test "requires entity_id and server_id" do
      log = Log.create_changeset(%{})

      assert :entity_id in Keyword.keys(log.errors)
      assert :server_id in Keyword.keys(log.errors)
    end
  end
end
