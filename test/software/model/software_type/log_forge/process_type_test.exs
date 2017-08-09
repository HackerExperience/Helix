defmodule Helix.Software.Model.SoftwareType.LogForgeTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Helix.Log.Model.Log
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.SoftwareType.LogForge

  describe "create/2" do
    test "returns changeset if invalid" do
      params = %{}
      modules = %{log_forger_edit: 1, log_forger_create: 1}

      assert {:error, changeset} = LogForge.create(params, modules)
      assert %Changeset{valid?: false} = changeset
    end

    test "requires target_log_id and entity_id" do
      params = %{}
      modules = %{log_forger_edit: 1, log_forger_create: 1}

      expected_errors = [:target_log_id, :entity_id]

      assert {:error, changeset} = LogForge.create(params, modules)
      errors = Keyword.keys(changeset.errors)
      assert Enum.all?(expected_errors, &(&1 in errors))
    end

    test "accepts binary input" do
      params = %{
        "target_log_id" => to_string(Log.ID.generate()),
        "message" => "WAKE ME UP INSIDE (can't wake up)",
        "entity_id" => to_string(Entity.ID.generate())
      }
      modules = %{log_forger_edit: 1, log_forger_create: 1}

      assert {:ok, %LogForge{}} = LogForge.create(params, modules)
    end

    test "accepts native erlang term entries" do
      params = %{
        target_log_id: Log.ID.generate(),
        message: "Oh yeah",
        entity_id: Entity.ID.generate()
      }
      modules = %{log_forger_edit: 1, log_forger_create: 1}

      assert {:ok, %LogForge{}} = LogForge.create(params, modules)
    end
  end

  describe "objective/3" do
    test "returns a higher objective when the revision count is bigger" do
      process_data = %LogForge{
        target_log_id: Log.ID.generate(),
        entity_id: Entity.ID.generate(),
        message: "ring ring ring banana phone",
        version: 100
      }
      log = %Log{
        log_id: process_data.target_log_id,
        server_id: Server.ID.generate(),
        entity_id: Entity.ID.generate(),
        message: ""
      }

      rev1 = LogForge.objective(process_data, log, 1)
      rev2 = LogForge.objective(process_data, log, 2)
      rev3 = LogForge.objective(process_data, log, 3)
      rev4 = LogForge.objective(process_data, log, 20)

      assert rev2 > rev1
      assert rev3 > rev2
      assert rev4 > rev3
    end

    test "ignores first revision that created the log" do
      process_data = %LogForge{
        target_log_id: Log.ID.generate(),
        entity_id: Entity.ID.generate(),
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

      x = LogForge.objective(process_data, same_entity_log, 3)
      y = LogForge.objective(process_data, diferent_entity_log, 3)

      # This is because on `x`, because the entity that started the log_forge
      # process is the same that originally created the log (and when a log is
      # created it starts with one revision), so we should ignore that first
      # revision (ie: instead of using `3` as the revision count, we consider
      # `3 - 1`)
      assert y > x
    end
  end
end
