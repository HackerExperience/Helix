defmodule Helix.Process.State.TOP.TOPServerTest do

  use Helix.Test.Case.Integration

  alias Helix.Test.Process.StaticProcessTypeExample
  alias Helix.Account.Action.Flow.Account, as: AccountFlow
  alias Helix.Process.State.TOP.Server, as: TOPServer
  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Account.Factory, as: AccountFactory

  defmodule ProcessThatCausesOverflow do
    defstruct []
    defimpl Helix.Process.Model.Process.ProcessType do
      def dynamic_resources(_),
        do: []
      def minimum(_),
        do: %{running: %{cpu: 999_999_999}}
      def kill(_, process, _),
        do: {%{Ecto.Changeset.change(process)| action: :delete}, []}
      def state_change(_, process, _, _),
        do: {process, []}
      def conclusion(data, process),
        do: state_change(data, process, :running, :complete)
    end
  end

  defp create_server do
    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    CacheHelper.sync_test()

    server
  end

  defp start_process(top, server_id) do
    params = %{
      gateway_id: server_id,
      target_server_id: server_id,
      process_data: %StaticProcessTypeExample{},
      process_type: "static_example_process",
      objective: %{cpu: 9_999_999}
    }

    TOPServer.create(top, params)
  end

  setup do
    server = create_server()

    {:ok, top} = TOPServer.start_link(server.server_id)

    {:ok, top: top, server: server}
  end

  describe "create/2" do
    test "succeeds with proper input", context do
      params = %{
        gateway_id: context.server.server_id,
        target_server_id: context.server.server_id,
        process_data: %StaticProcessTypeExample{},
        process_type: "static_example_process",
        objective: %{cpu: 9_999_999}
      }

      assert {:ok, _} = TOPServer.create(context.top, params)
    end

    test "fails if new process would cause resource overflow", context do
      params = %{
        gateway_id: context.server.server_id,
        target_server_id: context.server.server_id,
        process_data: %ProcessThatCausesOverflow{},
        process_type: "overflow_example",
        objective: %{cpu: 9_999_999}
      }

      assert {:error, :resources} == TOPServer.create(context.top, params)
    end
  end

  describe "priority/3" do
    test "changes the process priority", context do
      {:ok, process} = start_process(context.top, context.server.server_id)

      TOPServer.priority(context.top, process, 5)

      :timer.sleep(100)

      assert 5 == ProcessQuery.fetch(process.process_id).priority
    end
  end

  describe "pause/2" do
    test "changes state of process", context do
      {:ok, process} = start_process(context.top, context.server.server_id)

      TOPServer.pause(context.top, process)

      :timer.sleep(100)

      assert :paused == ProcessQuery.fetch(process.process_id).state
    end
  end

  describe "resume/2" do
    test "changes state of a paused process to running", context do
      {:ok, process} = start_process(context.top, context.server.server_id)

      TOPServer.pause(context.top, process)
      :timer.sleep(50)
      TOPServer.resume(context.top, process)
      :timer.sleep(50)

      assert :running == ProcessQuery.fetch(process.process_id).state
    end
  end

  describe "kill/2" do
    test "removes a process from a server", context do
      {:ok, process} = start_process(context.top, context.server.server_id)

      TOPServer.kill(context.top, process)

      :timer.sleep(100)

      refute ProcessQuery.fetch(process.process_id)
    end
  end
end
