defmodule Helix.Software.Model.SoftwareType.LogForgeTest do

  use ExUnit.Case, async: true

  alias Ecto.Changeset
  alias Helix.Log.Model.Log
  alias Helix.Entity.Model.Entity
  alias Helix.Process.API.View.Process, as: ProcessView
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.SoftwareType.LogForge

  alias Helix.Process.Factory, as: ProcessFactory

  describe "create/2" do
    test "returns changeset if invalid" do
      modules = %{log_forger_edit: 1, log_forger_create: 1}
      params = %{}

      assert {:error, changeset} = LogForge.create(params, modules)
      assert %Changeset{valid?: false} = changeset
    end

    test "requires operation and entity_id" do
      modules = %{log_forger_edit: 1, log_forger_create: 1}
      params = %{}

      expected_errors = [:operation, :entity_id]

      assert {:error, changeset} = LogForge.create(params, modules)
      errors = Keyword.keys(changeset.errors)
      assert Enum.all?(expected_errors, &(&1 in errors))
    end

    test "requires target_log_id when operation is edit" do
      modules = %{log_forger_edit: 1, log_forger_create: 1}
      params = %{message: "", operation: "edit"}

      expected_errors = [:target_log_id]

      assert {:error, changeset} = LogForge.create(params, modules)
      errors = Keyword.keys(changeset.errors)
      assert Enum.all?(expected_errors, &(&1 in errors))
    end

    test "requires target_server_id when operation is create" do
      modules = %{log_forger_edit: 1, log_forger_create: 1}
      params = %{message: "", operation: "create"}

      expected_errors = [:target_server_id]

      assert {:error, changeset} = LogForge.create(params, modules)
      errors = Keyword.keys(changeset.errors)
      assert Enum.all?(expected_errors, &(&1 in errors))
    end

    test "accepts binary input" do
      modules = %{log_forger_edit: 1, log_forger_create: 1}
      params_edit = %{
        "target_log_id" => to_string(Log.ID.generate()),
        "message" => "WAKE ME UP INSIDE (can't wake up)",
        "operation" => "edit",
        "entity_id" => to_string(Entity.ID.generate())
      }
      params_create = %{
        "target_server_id" => to_string(Server.ID.generate()),
        "message" => "A weapon to surpass Metal Gear",
        "operation" => "create",
        "entity_id" => to_string(Entity.ID.generate())
      }

      assert {:ok, %LogForge{}} = LogForge.create(params_edit, modules)
      assert {:ok, %LogForge{}} = LogForge.create(params_create, modules)
    end

    test "accepts native erlang term entries" do
      modules = %{log_forger_edit: 1, log_forger_create: 1}
      params_edit = %{
        target_log_id: Log.ID.generate(),
        message: "Oh yeah",
        operation: "edit",
        entity_id: Entity.ID.generate()
      }
      params_create = %{
        target_server_id: Server.ID.generate(),
        message: "Oh noes",
        operation: "create",
        entity_id: Entity.ID.generate()
      }

      assert {:ok, %LogForge{}} = LogForge.create(params_edit, modules)
      assert {:ok, %LogForge{}} = LogForge.create(params_create, modules)
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

    test "returns a higher objective the higher the forger version is" do
      data = %LogForge{
        target_log_id: Log.ID.generate(),
        entity_id: Entity.ID.generate(),
        operation: "edit",
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

  describe "create_objective/1" do
    test "returns a higher objective the higher the forger version is" do
      data = %LogForge{
        target_server_id: Server.ID.generate(),
        entity_id: Entity.ID.generate(),
        operation: "create",
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
    test "returns target_log_id on remote" do
      process = process_to_render(:edit)
      data = process.process_data
      server = Server.ID.generate()
      entity = Entity.ID.generate()

      rendered = ProcessView.render(data, process, server, entity)

      assert %{target_log_id: %Log.ID{}} = rendered
    end

    test "returns target_log_id and version on local" do
      process = process_to_render(:edit)
      data = process.process_data
      server = process.gateway_id
      entity = Entity.ID.generate()
      version = data.version

      rendered = ProcessView.render(data, process, server, entity)

      assert %{target_log_id: %Log.ID{}, version: ^version} = rendered
    end

    test "returns a map on remote" do
      process = process_to_render(:edit)
      data = process.process_data
      server = Server.ID.generate()
      entity = Entity.ID.generate()

      rendered = ProcessView.render(data, process, server, entity)

      keys = Map.keys(rendered)
      expected = ~w/
        process_id
        gateway_id
        target_server_id
        network_id
        connection_id
        process_type
        target_log_id/a

      assert Enum.sort(expected) == Enum.sort(keys)
    end

    test "returns a map on local" do
      process = process_to_render(:edit)
      data = process.process_data
      server = Server.ID.generate()
      entity = data.entity_id

      rendered = ProcessView.render(data, process, server, entity)

      keys = Map.keys(rendered)
      expected = ~w/
        process_id
        gateway_id
        target_server_id
        network_id
        connection_id
        process_type
        state
        objective
        processed
        allocated
        priority
        creation_time
        target_log_id
        version/a

      assert Enum.sort(expected) == Enum.sort(keys)
    end
  end

  describe "ProcessView.render/4 for create operation" do
    test "returns version on local" do
      process = process_to_render(:create)
      data = process.process_data
      server = process.gateway_id
      entity = Entity.ID.generate()
      version = data.version

      rendered = ProcessView.render(data, process, server, entity)

      assert %{version: ^version} = rendered
    end

    test "returns a map on remote" do
      process = process_to_render(:create)
      data = process.process_data
      server = Server.ID.generate()
      entity = Entity.ID.generate()

      rendered = ProcessView.render(data, process, server, entity)

      keys = Map.keys(rendered)
      expected = ~w/
        process_id
        gateway_id
        target_server_id
        network_id
        connection_id
        process_type/a

      assert Enum.sort(expected) == Enum.sort(keys)
    end

    test "returns a map on local" do
      process = process_to_render(:create)
      data = process.process_data
      server = Server.ID.generate()
      entity = data.entity_id

      rendered = ProcessView.render(data, process, server, entity)

      keys = Map.keys(rendered)
      expected = ~w/
        process_id
        gateway_id
        target_server_id
        network_id
        connection_id
        process_type
        state
        objective
        processed
        allocated
        priority
        creation_time
        version/a

      assert Enum.sort(expected) == Enum.sort(keys)
    end
  end

  defp process_to_render(:edit) do
    %{
      base_process_to_render()|
        process_data: %LogForge{
          target_log_id: Log.ID.generate(),
          entity_id: Entity.ID.generate(),
          operation: "edit",
          message: "",
          version: 100
        }
    }
  end

  defp process_to_render(:create) do
    %{
      base_process_to_render()|
        process_data: %LogForge{
          target_server_id: Server.ID.generate(),
          entity_id: Entity.ID.generate(),
          operation: "create",
          message: "",
          version: 100
        }
    }
  end

  defp base_process_to_render do
    ProcessFactory.build(:process)
  end
end
