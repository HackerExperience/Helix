defmodule Helix.Software.Model.SoftwareType.LogForgeTest do

  use Helix.Test.Case.Integration

  alias Ecto.Changeset
  alias Helix.Log.Model.Log
  alias Helix.Entity.Model.Entity
  alias Helix.Process.Model.Processable
  alias Helix.Process.Public.View.Process, as: ProcessView
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.SoftwareType.LogForge

  alias Helix.Test.Process.Helper, as: ProcessHelper
  alias Helix.Test.Process.Setup, as: ProcessSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Process.View.Helper, as: ProcessViewHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  defp forger_file do
    SoftwareSetup.file!(type: :log_forger)
  end

  describe "create/2" do
    test "returns changeset if invalid" do
      assert {:error, changeset} = LogForge.create(forger_file(), %{})
      assert %Changeset{valid?: false} = changeset
    end

    test "requires operation and entity_id" do
      expected_errors = [:operation, :entity_id]

      assert {:error, changeset} = LogForge.create(forger_file(), %{})
      errors = Keyword.keys(changeset.errors)
      assert Enum.sort(expected_errors) == Enum.sort(errors)
    end

    test "requires target_log_id when operation is edit" do
      params = %{message: "", operation: :edit}

      expected_errors = [:target_log_id]

      assert {:error, changeset} = LogForge.create(forger_file(), params)
      errors = Keyword.keys(changeset.errors)
      assert Enum.all?(expected_errors, &(&1 in errors))
    end

    test "requires target_id when operation is create" do
      params = %{message: "", operation: :create}

      expected_errors = [:target_id]

      assert {:error, changeset} = LogForge.create(forger_file(), params)
      errors = Keyword.keys(changeset.errors)
      assert Enum.all?(expected_errors, &(&1 in errors))
    end

    test "accepts binary input" do
      params_edit = %{
        "target_log_id" => to_string(Log.ID.generate()),
        "message" => "WAKE ME UP INSIDE (can't wake up)",
        "operation" => :edit,
        "entity_id" => to_string(Entity.ID.generate())
      }
      params_create = %{
        "target_id" => to_string(Server.ID.generate()),
        "message" => "A weapon to surpass Datal Gear",
        "operation" => :create,
        "entity_id" => to_string(Entity.ID.generate())
      }

      assert {:ok, %LogForge{}} = LogForge.create(forger_file(), params_edit)
      assert {:ok, %LogForge{}} = LogForge.create(forger_file(), params_create)
    end

    test "accepts native erlang term entries" do
      params_edit = %{
        target_log_id: Log.ID.generate(),
        message: "Oh yeah",
        operation: :edit,
        entity_id: Entity.ID.generate()
      }
      params_create = %{
        target_id: Server.ID.generate(),
        message: "Oh noes",
        operation: :create,
        entity_id: Entity.ID.generate()
      }

      assert {:ok, %LogForge{}} = LogForge.create(forger_file(), params_edit)
      assert {:ok, %LogForge{}} = LogForge.create(forger_file(), params_create)
    end
  end

  describe "edit_objective/3" do
    test "returns a higher objective when the revision count is bigger" do
      process_data = %LogForge{
        target_log_id: Log.ID.generate(),
        entity_id: Entity.ID.generate(),
        operation: :edit,
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

    test "returns a higher objective the higher the forger version is" do
      data = %LogForge{
        target_log_id: Log.ID.generate(),
        entity_id: Entity.ID.generate(),
        operation: :edit,
        message: "Okay robot",
        version: 100
      }
      log = %Log{
        log_id: data.target_log_id,
        server_id: Server.ID.generate(),
        entity_id: Entity.ID.generate(),
        message: ""
      }

      rev1 = LogForge.edit_objective(data, log, 1)
      rev2 = LogForge.edit_objective(%{data| version: 200}, log, 1)
      rev3 = LogForge.edit_objective(%{data| version: 300}, log, 1)
      rev4 = LogForge.edit_objective(%{data| version: 999}, log, 1)

      assert rev2 > rev1
      assert rev3 > rev2
      assert rev4 > rev3
    end

    test "ignores first revision that created the log" do
      process_data = %LogForge{
        target_log_id: Log.ID.generate(),
        entity_id: Entity.ID.generate(),
        operation: :edit,
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

  describe "create_objective/1" do
    test "returns a higher objective the higher the forger version is" do
      data = %LogForge{
        target_id: Server.ID.generate(),
        entity_id: Entity.ID.generate(),
        operation: :create,
        message: "Digital style",
        version: 100
      }

      rev1 = LogForge.create_objective(data)
      rev2 = LogForge.create_objective(%{data| version: 200})
      rev3 = LogForge.create_objective(%{data| version: 300})
      rev4 = LogForge.create_objective(%{data| version: 999})

      assert rev2 > rev1
      assert rev3 > rev2
      assert rev4 > rev3
    end
  end

  describe "ProcessView.render/4 for edit operation" do
    test "both partial and full processes returns target_log_id" do
      {process, %{target_entity_id: victim_entity}} = log_forger_process(:edit)
      data = process.data

      victim_server = process.target_id
      attacker_entity = process.source_entity_id

      # Victim rendering Log process on her own server. Partial access.
      victim_view =
        ProcessView.render(data, process, victim_server, victim_entity)

      # Attacker rendering Log process on Victim server. Full access.
      attacker_view =
        ProcessView.render(data, process, victim_server, attacker_entity)

      ProcessViewHelper.assert_keys(victim_view, :partial, &pview_edit_data/1)
      ProcessViewHelper.assert_keys(attacker_view, :full, &pview_edit_data/1)

      assert victim_view.data.target_log_id
      assert is_binary(victim_view.data.target_log_id)
      assert attacker_view.data.target_log_id == to_string(data.target_log_id)

      TOPHelper.top_stop(process.gateway_id)
    end

    defp pview_edit_data(_) do
      [:target_log_id]
      |> Enum.sort()
    end
  end

  describe "ProcessView.render/4 for create operation" do
    test "both partial and full process adds no complement" do
      {process, _} = log_forger_process(:create)
      data = process.data

      attacker_server = process.gateway_id
      victim_server = process.target_id
      attacker_entity = process.source_entity_id
      third_entity = Entity.ID.generate()

      # Third-party rendering Log process on victim. Partial access.
      third_view =
        ProcessView.render(data, process, victim_server, third_entity)

      # Attacker who started the Log process, on his own server. Full access.
      attacker_view =
        ProcessView.render(data, process, attacker_server, attacker_entity)

      ProcessViewHelper.assert_keys(attacker_view, :full)
      ProcessViewHelper.assert_keys(third_view, :partial)

      TOPHelper.top_stop(process.gateway_id)
    end
  end

  describe "after_read_hook/1" do
    test "serializes to the internal representation" do
      {process_create, _} = log_forger_process(:create)
      {process_edit, _} = log_forger_process(:edit)

      db_create = ProcessHelper.raw_get(process_create.process_id)
      db_edit = ProcessHelper.raw_get(process_edit.process_id)

      serialized_create = Processable.after_read_hook(db_create.data)
      serialized_edit = Processable.after_read_hook(db_edit.data)

      # Create process has `target_log_id` equals nil
      refute serialized_create.target_log_id
      assert %Entity.ID{} = serialized_create.entity_id
      assert %Server.ID{} = serialized_create.target_id
      assert serialized_create.operation == :create
      assert serialized_create.message
      assert serialized_create.version

      # Edit has valid `target_log_id`
      assert %Entity.ID{} = serialized_edit.entity_id
      assert %Log.ID{} = serialized_edit.target_log_id
      assert %Server.ID{} = serialized_edit.target_id
      assert serialized_edit.operation == :edit
      assert serialized_edit.message
      assert serialized_edit.version

      TOPHelper.top_stop()
    end
  end

  defp log_forger_process(operation) do
    ProcessSetup.process(
      fake_server: true,
      type: :forge,
      data: [operation: operation]
    )
  end
end
