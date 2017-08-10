defmodule Helix.Software.Model.SoftwareType.LogForgeTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Helix.Log.Model.Log
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.SoftwareType.LogForge

  describe "create/2" do
    test "returns changeset if invalid" do
      server_id = Server.ID.generate()
      params = %{}
      modules = %{log_forger_edit: 1, log_forger_create: 1}

      assert {:error, changeset} = LogForge.create(params, server_id, modules)
      assert %Changeset{valid?: false} = changeset
    end

    test "requires operation and entity_id" do
      server_id = Server.ID.generate()
      params = %{}
      modules = %{log_forger_edit: 1, log_forger_create: 1}

      expected_errors = [:operation, :entity_id]

      assert {:error, changeset} = LogForge.create(params, server_id, modules)
      errors = Keyword.keys(changeset.errors)
      assert Enum.all?(expected_errors, &(&1 in errors))
    end

    test "accepts binary input" do
      server_id = Server.ID.generate()
      params = %{
        "target_log_id" => to_string(Log.ID.generate()),
        "message" => "WAKE ME UP INSIDE (can't wake up)",
        "operation" => "edit",
        "entity_id" => to_string(Entity.ID.generate())
      }
      modules = %{log_forger_edit: 1, log_forger_create: 1}

      assert {:ok, %LogForge{}} = LogForge.create(params, server_id, modules)
    end

    test "accepts native erlang term entries" do
      server_id = Server.ID.generate()
      params = %{
        target_log_id: Log.ID.generate(),
        message: "Oh yeah",
        operation: "edit",
        entity_id: Entity.ID.generate()
      }
      modules = %{log_forger_edit: 1, log_forger_create: 1}

      assert {:ok, %LogForge{}} = LogForge.create(params, server_id, modules)
    end
  end

  describe "edit_objective/3" do
    test "returns a higher objective when the revision count is bigger" do
      process_data = %LogForge{
        target_log_id: Log.ID.generate(),
        entity_id: Entity.ID.generate(),
        operation: "edit",
        message: "ring ring ring banana phone",
        version: 100
      }
      log = %Log{
        log_id: process_data.target_log_id,
        server_id: Server.ID.generate(),
        entity_id: Entity.ID.generate(),
        message: ""
      }

      rev1 = LogForge.edit_objective(process_data, log, 1)
      rev2 = LogForge.edit_objective(process_data, log, 2)
      rev3 = LogForge.edit_objective(process_data, log, 3)
      rev4 = LogForge.edit_objective(process_data, log, 20)

      assert rev2 > rev1
      assert rev3 > rev2
      assert rev4 > rev3
    end

    test "ignores first revision that created the log" do
      process_data = %LogForge{
        target_log_id: Log.ID.generate(),
        entity_id: Entity.ID.generate(),
        operation: "edit",
        message: "ring ring ring banana phone",
        version: 100
      }
      same_entity_log = %Log{
        log_id: process_data.target_log_id,
        server_id: Server.ID.generate(),
        entity_id: process_data.entity_id,
        message: ""
      }
      diferent_entity_log = %{same_entity_log| entity_id: Entity.ID.generate()}

      x = LogForge.edit_objective(process_data, same_entity_log, 3)
      y = LogForge.edit_objective(process_data, diferent_entity_log, 3)

      # This is because on `x`, because the entity that started the log_forge
      # process is the same that originally created the log (and when a log is
      # created it starts with one revision), so we should ignore that first
      # revision (ie: instead of using `3` as the revision count, we consider
      # `3 - 1`)
      assert y > x
    end
  end
end
