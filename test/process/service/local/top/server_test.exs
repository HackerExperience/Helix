defmodule Helix.Process.Service.Local.TOP.ServerTest do

  use Helix.Test.IntegrationCase

  alias Helix.Process.TestHelper.StaticProcessTypeExample
  alias Helix.Process.Service.Local.TOP.Server

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
    alias Helix.Account.Service.Flow.Account, as: AccountFlow
    alias Helix.Account.Factory, as: AccountFactory

    account = AccountFactory.insert(:account)
    {:ok, %{server: server}} = AccountFlow.setup_account(account)

    server
  end

  setup do
    server = create_server()

    {:ok, top} = Server.start_link(server.server_id)

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

      assert {:ok, _} = Server.create(context.top, params)
    end

    test "fails if new process would cause resource overflow", context do
      params = %{
        gateway_id: context.server.server_id,
        target_server_id: context.server.server_id,
        process_data: %ProcessThatCausesOverflow{},
        process_type: "overflow_example",
        objective: %{cpu: 9_999_999}
      }

      assert {:error, :resources} == Server.create(context.top, params)
    end
  end
end
