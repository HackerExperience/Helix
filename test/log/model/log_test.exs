defmodule Helix.Log.Model.LogTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Helix.Log.Model.Log

  alias Helix.Test.Entity.Helper, as: EntityHelper
  alias Helix.Test.Server.Helper, as: ServerHelper

  @moduletag :unit

  describe "log creation" do
    test "adds timestamp" do
      params =
        %{
          server_id: ServerHelper.id(),
          entity_id: EntityHelper.id(),
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
