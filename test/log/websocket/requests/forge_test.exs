defmodule Helix.Log.Websocket.Requests.ForgeTest do

  use Helix.Test.Case.Integration

  import Helix.Test.Macros

  alias Helix.Websocket.Requestable
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Log.Websocket.Requests.Forge, as: LogForgeRequest

  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Log.Setup, as: LogSetup

  @mock_socket ChannelSetup.mock_server_socket()

  describe "LogForgeRequest.check_params/2" do
    test "validates expected data (create)" do
      log_info = LogHelper.log_info()
      {req_log_type, req_log_data} = request_log_info(log_info)

      params = %{
        "action" => "create",
        "log_type" => req_log_type,
        "log_data" => req_log_data
      }

      request = LogForgeRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @mock_socket)

      assert request.params.action == :create
      assert request.params.log_info == log_info
    end

    test "validates expected data (edit)" do
      log_id = LogHelper.id()
      log_info = LogHelper.log_info()
      {req_log_type, req_log_data} = request_log_info(log_info)

      params = %{
        "action" => "edit",
        "log_id" => to_string(log_id),
        "log_type" => req_log_type,
        "log_data" => req_log_data
      }

      request = LogForgeRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @mock_socket)

      assert request.params.action == :edit
      assert request.params.log_id == log_id
      assert request.params.log_info == log_info
    end

    test "rejects when log_info is invalid" do
      p_base = %{"action" => "create"}

      p0 =
        %{
          "log_type" => "invalid_type",
          "log_data" => %{}
        } |> Map.merge(p_base)
      p1 =
        %{
          "log_type" => "error",
          "log_data" => "string"
        } |> Map.merge(p_base)

      # missing entries
      p2 =
        %{
          "log_type" => "connection_bounced",
          "log_data" => %{"ip_prev" => "1.2.3.4", "network_id" => "::"}
        } |> Map.merge(p_base)

      # invalid data type
      p3 =
        %{
          "log_type" => "connection_bounced",
          "log_data" => nil
        } |> Map.merge(p_base)

      # missing `log_data`
      p4 =
        %{
          "log_type" => "connection_bounced",
        } |> Map.merge(p_base)

      r0 = LogForgeRequest.new(p0)
      r1 = LogForgeRequest.new(p1)
      r2 = LogForgeRequest.new(p2)
      r3 = LogForgeRequest.new(p3)
      r4 = LogForgeRequest.new(p4)

      assert {:error, data0, _} = Requestable.check_params(r0, @mock_socket)
      assert {:error, data1, _} = Requestable.check_params(r1, @mock_socket)
      assert {:error, data2, _} = Requestable.check_params(r2, @mock_socket)
      assert {:error, data3, _} = Requestable.check_params(r3, @mock_socket)
      assert {:error, data4, _} = Requestable.check_params(r4, @mock_socket)

      assert data0.message == "bad_log_type"
      assert data0 == data1

      assert data2.message == "bad_log_data"
      assert data3 == data2
      assert data4 == data3
    end

    test "rejects when `log_id` is missing or invalid" do
      {req_log_type, req_log_data} = request_log_info()

      p_base = %{
        "action" => "edit",
        "log_type" => req_log_type,
        "log_data" => req_log_data
      }

      p_invalid = %{"log_id" => "w00t"} |> Map.merge(p_base)
      p_missing = p_base

      r_invalid = LogForgeRequest.new(p_invalid)
      r_missing = LogForgeRequest.new(p_missing)

      assert {:error, data1, _} =
        Requestable.check_params(r_missing, @mock_socket)
      assert {:error, data2, _} =
        Requestable.check_params(r_invalid, @mock_socket)

      assert data1.message == "bad_request"
      assert data2 == data1
    end

    test "rejects when action is missing or invalid" do
      {req_log_type, req_log_data} = request_log_info()

      p_base = %{
        "log_type" => req_log_type,
        "log_data" => req_log_data
      }

      p_invalid = %{"action" => "asdf"} |> Map.merge(p_base)
      p_missing = p_base

      r_invalid = LogForgeRequest.new(p_invalid)
      r_missing = LogForgeRequest.new(p_missing)

      assert {:error, data1, _} =
        Requestable.check_params(r_missing, @mock_socket)
      assert {:error, data2, _} =
        Requestable.check_params(r_invalid, @mock_socket)

      assert data1.message == "bad_action"
      assert data2 == data1
    end
  end

  describe "LogForgeRequest.check_permissions/2" do
    test "accepts when everything is OK" do
      gateway = ServerSetup.server!()
      target_id = ServerHelper.id()
      forger = SoftwareSetup.log_forger!(server_id: gateway.server_id)

      {req_log_type, req_log_data} = request_log_info()

      params =
        %{
          "action" => Enum.random(["create", "edit"]),
          "log_type" => req_log_type,
          "log_data" => req_log_data
        }

      params =
        if params["action"] == "edit" do
          log = LogSetup.log!(server_id: target_id)
          Map.put(params, "log_id", to_string(log.log_id))
        else
          params
        end

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, destination_id: target_id
        )

      request = LogForgeRequest.new(params)

      {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)

      assert request.meta.forger == forger
      assert request.meta.gateway == gateway

      if request.params.action == :edit do
        assert to_string(request.meta.log.log_id) == params["log_id"]
        assert request.meta.log.server_id == target_id
      end
    end

    test "rejects when player does not have a forger" do
      gateway = ServerSetup.server!()
      target_id = ServerHelper.id()

      {req_log_type, req_log_data} = request_log_info()

      params =
        %{
          "action" => Enum.random(["create", "edit"]),
          "log_type" => req_log_type,
          "log_data" => req_log_data
        }

      params =
        if params["action"] == "edit" do
          log = LogSetup.log!(server_id: target_id)
          Map.put(params, "log_id", to_string(log.log_id))
        else
          params
        end

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, destination_id: target_id
        )

      request = LogForgeRequest.new(params)

      {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, reason, _} =
        Requestable.check_permissions(request, socket)

      assert reason.message == "forger_not_found"
    end

    test "rejects when attempting to edit another server's log (edit)" do
      gateway = ServerSetup.server!()

      {req_log_type, req_log_data} = request_log_info()

      log = LogSetup.log!()

      params =
        %{
          "action" => "edit",
          "log_id" => to_string(log.log_id),
          "log_type" => req_log_type,
          "log_data" => req_log_data
        }

      # socket's `destination` is different from `log.server_id`
      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, destination_id: ServerHelper.id()
        )

      request = LogForgeRequest.new(params)

      {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, reason, _} =
        Requestable.check_permissions(request, socket)

      assert reason.message == "log_not_belongs"
    end
  end

  describe "handle_request/2" do
    test "starts the process (create, local)" do
      log_info = {log_type, log_data} = LogHelper.log_info()

      gateway = ServerSetup.server!()

      forger = SoftwareSetup.log_forger!(server_id: gateway.server_id)

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, own_server: true
        )

      params = %{log_info: log_info, action: :create}
      meta = %{forger: forger, gateway: gateway}

      request = RequestHelper.mock_request(LogForgeRequest, params, meta)

      assert {:ok, _request} = Requestable.handle_request(request, socket)

      assert [process] = ProcessQuery.get_processes_on_server(gateway.server_id)

      assert process.type == :log_forge_create
      assert process.gateway_id == process.target_id
      assert process.src_file_id == forger.file_id
      refute process.src_connection_id
      assert process.data.forger_version == forger.modules.log_create.version
      assert process.data.log_type == log_type
      assert_map_str process.data.log_data, Map.from_struct(log_data)

      TOPHelper.top_stop(gateway)
    end

    test "starts the process (create, remote)" do
      log_info = {log_type, log_data} = LogHelper.log_info()

      gateway = ServerSetup.server!()
      target = ServerSetup.server!()

      forger = SoftwareSetup.log_forger!(server_id: gateway.server_id)

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id,
          destination_id: target.server_id,
          real_connection?: true
        )

      params = %{log_info: log_info, action: :create}
      meta = %{forger: forger, gateway: gateway}

      request = RequestHelper.mock_request(LogForgeRequest, params, meta)

      assert {:ok, _request} = Requestable.handle_request(request, socket)

      assert [process] = ProcessQuery.get_processes_on_server(gateway.server_id)

      assert process.type == :log_forge_create
      assert process.target_id == target.server_id
      assert process.src_file_id == forger.file_id
      assert process.src_connection_id == socket.assigns.ssh.connection_id
      assert process.data.forger_version == forger.modules.log_create.version
      assert process.data.log_type == log_type
      assert_map_str process.data.log_data, Map.from_struct(log_data)

      TOPHelper.top_stop(gateway)
    end

    test "starts the process (edit, local)" do
      log_info = {log_type, log_data} = LogHelper.log_info()

      gateway = ServerSetup.server!()

      log = LogSetup.log!(server_id: gateway.server_id)
      forger = SoftwareSetup.log_forger!(server_id: gateway.server_id)

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, own_server: true
        )

      params = %{log_info: log_info, action: :edit}
      meta = %{log: log, forger: forger, gateway: gateway}

      request = RequestHelper.mock_request(LogForgeRequest, params, meta)

      assert {:ok, _request} = Requestable.handle_request(request, socket)

      assert [process] = ProcessQuery.get_processes_on_server(gateway.server_id)

      assert process.type == :log_forge_edit
      assert process.gateway_id == process.target_id
      assert process.src_file_id == forger.file_id
      refute process.src_connection_id
      assert process.data.forger_version == forger.modules.log_edit.version
      assert process.data.log_type == log_type
      assert_map_str process.data.log_data, Map.from_struct(log_data)

      TOPHelper.top_stop(gateway)
    end

    test "starts the process (edit, remote)" do
      log_info = {log_type, log_data} = LogHelper.log_info()

      gateway = ServerSetup.server!()
      target = ServerSetup.server!()

      log = LogSetup.log!(server_id: gateway.server_id)
      forger = SoftwareSetup.log_forger!(server_id: gateway.server_id)

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id,
          destination_id: target.server_id,
          real_connection?: true
        )

      params = %{log_info: log_info, action: :edit}
      meta = %{log: log, forger: forger, gateway: gateway}

      request = RequestHelper.mock_request(LogForgeRequest, params, meta)

      assert {:ok, _request} = Requestable.handle_request(request, socket)

      assert [process] = ProcessQuery.get_processes_on_server(gateway.server_id)

      assert process.type == :log_forge_edit
      assert process.target_id == target.server_id
      assert process.src_file_id == forger.file_id
      assert process.src_connection_id == socket.assigns.ssh.connection_id
      assert process.data.forger_version == forger.modules.log_edit.version
      assert process.data.log_type == log_type
      assert_map_str process.data.log_data, Map.from_struct(log_data)

      TOPHelper.top_stop(gateway)
    end
  end

  defp request_log_info,
    do: LogHelper.log_info() |> request_log_info()
  defp request_log_info({log_type, log_data}) do
    # Phoenix input has this format: %{"map" => "string"}
    stringified_log_data =
      log_data
      |> Map.from_struct()
      |> Enum.reduce([], fn {k, v}, acc ->
        [{to_string(k), to_string(v)} | acc]
      end)
      |> Enum.into(%{})

    {to_string(log_type), stringified_log_data}
  end
end
