defmodule Helix.Process.Action.ProcessTest do

  use Helix.Test.Case.Integration

  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Process.Setup, as: ProcessSetup

  describe "create/1" do
    test "process is created; event is defined" do

      {server, %{entity: entity}} = ServerSetup.server()
      {_, %{params: params}} =
        ProcessSetup.fake_process(
          gateway_id: server.server_id,
          single_server: true,
          entity_id: entity.entity_id
        )

      assert {:ok, process, [event]} = ProcessAction.create(params)

      # Created the process...
      assert process.process_id
      assert process.gateway_id == server.server_id
      assert process.source_entity_id == entity.entity_id

      # And actually inserted it into the DB
      assert ProcessQuery.fetch(process.process_id)

      # Process hasn't been confirmed (allocated) yet.
      assert event.confirmed == false
    end
  end
end
