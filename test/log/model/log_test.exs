defmodule Helix.Log.Model.LogTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Log.Model.Log

  @moduletag :unit

  describe "log creation" do
    test "adds timestamp" do
      params =
        %{
          server_id: Server.ID.generate(),
          entity_id: Entity.ID.generate(),
          message: "wut"
        }

      changeset = Log.create_changeset(params)
      assert changeset.valid?

      log = Changeset.apply_changes(changeset)

      assert log.message == params.message
      assert log.server_id == params.server_id
      assert log.entity_id == params.entity_id
      assert %DateTime{} = log.creation_time
      assert log.revisions

      [revision] = log.revisions

      assert revision.entity_id == params.entity_id
      assert revision.message == params.message
      refute revision.forge_version
      assert revision.creation_time == log.creation_time
    end
  end
end
