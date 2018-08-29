defmodule Helix.Log.Websocket.Requests.RecoverTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Log.Websocket.Requests.Recover, as: LogRecoverRequest

  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Log.Helper, as: LogHelper
  alias Helix.Test.Log.Setup, as: LogSetup

  @mock_socket ChannelSetup.mock_server_socket()

  describe "LogRecoverRequest.check_params/2" do
    test "validates expected data (global)" do
      params = %{"method" => "global"}

      request = LogRecoverRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @mock_socket)

      assert request.params.method == :global
    end

    test "validates expected data (custom)" do
      log_id = LogHelper.id()

      params =
        %{
          "method" => "custom",
          "log_id" => to_string(log_id)
        }

      request = LogRecoverRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @mock_socket)

      assert request.params.method == :custom
      assert request.params.log_id == log_id
    end

    test "rejects when `log_id` is missing or invalid" do
      p_base = %{"method" => "custom"}

      p0 = %{"log_id" => "abcd"} |> Map.merge(p_base)
      p1 = %{"log_id" => nil} |> Map.merge(p_base)
      p2 = %{} |> Map.merge(p_base)

      req0 = LogRecoverRequest.new(p0)
      req1 = LogRecoverRequest.new(p1)
      req2 = LogRecoverRequest.new(p2)

      assert {:error, reason0, _} = Requestable.check_params(req0, @mock_socket)
      assert {:error, reason1, _} = Requestable.check_params(req1, @mock_socket)
      assert {:error, reason2, _} = Requestable.check_params(req2, @mock_socket)

      assert reason0.message == "bad_request"
      assert reason1 == reason0
      assert reason2 == reason1
    end

    test "rejects when `method` is wrong" do
      p0 = %{"method" => "invalid"}
      p1 = %{"method" => nil}
      p2 = %{"method" => "custom"}

      req0 = LogRecoverRequest.new(p0)
      req1 = LogRecoverRequest.new(p1)
      req2 = LogRecoverRequest.new(p2)

      assert {:error, reason0, _} = Requestable.check_params(req0, @mock_socket)
      assert {:error, reason1, _} = Requestable.check_params(req1, @mock_socket)
      assert {:error, reason2, _} = Requestable.check_params(req2, @mock_socket)

      assert reason0.message == "bad_method"
      assert reason1 == reason0
      assert reason2.message == "bad_request"
    end
  end

  describe "LogRecoverRequest.check_permissions/2" do
    test "accepts when everything is OK" do
      gateway = ServerSetup.server!()
      target_id = ServerHelper.id()
      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      params = %{"method" => Enum.random(["global", "custom"])}

      params =
        if params["method"] == "custom" do
          log = LogSetup.log!(server_id: target_id)
          Map.put(params, "log_id", to_string(log.log_id))
        else
          params
        end

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, destination_id: target_id
        )

      request = LogRecoverRequest.new(params)

      {:ok, request} = Requestable.check_params(request, socket)
      assert {:ok, request} = Requestable.check_permissions(request, socket)

      assert request.meta.recover == recover
      assert request.meta.gateway == gateway

      if request.params.method == :custom do
        assert to_string(request.meta.log.log_id) == params["log_id"]
        assert request.meta.log.server_id == target_id
      end

    end

    test "rejects when player does not have a recover" do
      gateway = ServerSetup.server!()
      target_id = ServerHelper.id()

      params = %{"method" => Enum.random(["global", "custom"])}

      params =
      if params["method"] == "custom" do
        log = LogSetup.log!(server_id: target_id)
        Map.put(params, "log_id", to_string(log.log_id))
      else
        params
      end

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, destination_id: target_id
        )

      request = LogRecoverRequest.new(params)

      {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, reason, _} =
        Requestable.check_permissions(request, socket)

      assert reason.message == "recover_not_found"
    end

    test "rejects when attempting to recover another server's log (custom)" do
      gateway = ServerSetup.server!()
      log = LogSetup.log!()

      params =
        %{
          "method" => "custom",
          "log_id" => to_string(log.log_id),
        }

      # socket's `destination` is different from `log.server_id`
      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, destination_id: ServerHelper.id()
        )

      request = LogRecoverRequest.new(params)

      {:ok, request} = Requestable.check_params(request, socket)
      assert {:error, reason, _} =
        Requestable.check_permissions(request, socket)

      assert reason.message == "log_not_belongs"
    end
  end

  describe "LogRecoverRequest.handle_request/2" do
    test "starts the process (global, local, no recoverable logs)" do
      gateway = ServerSetup.server!()

      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, own_server: true
        )

      params = %{method: :global}
      meta = %{recover: recover, gateway: gateway}

      request = RequestHelper.mock_request(LogRecoverRequest, params, meta)

      assert {:ok, _request} = Requestable.handle_request(request, socket)

      assert [process] = ProcessQuery.get_processes_on_server(gateway.server_id)

      assert process.type == :log_recover_global
      assert process.gateway_id == process.target_id
      assert process.src_file_id == recover.file_id
      refute process.src_connection_id
      assert process.data.recover_version == recover.modules.log_recover.version

      # No log being recovered because there are no recoverable logs on server
      refute process.tgt_log_id

      TOPHelper.top_stop(gateway)
    end

    test "starts the process (global, remote, with recoverable logs)" do
      gateway = ServerSetup.server!()
      target = ServerSetup.server!()

      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      # Add a recoverable log to the target server
      log = LogSetup.log!(server_id: target.server_id, revisions: 2)

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id,
          destination_id: target.server_id,
          real_connection?: true
        )

      params = %{method: :global}
      meta = %{recover: recover, gateway: gateway}

      request = RequestHelper.mock_request(LogRecoverRequest, params, meta)

      assert {:ok, _request} = Requestable.handle_request(request, socket)

      assert [process] = ProcessQuery.get_processes_on_server(gateway.server_id)

      assert process.type == :log_recover_global
      assert process.target_id == target.server_id
      assert process.src_file_id == recover.file_id
      assert process.src_connection_id == socket.assigns.ssh.connection_id
      assert process.data.recover_version == recover.modules.log_recover.version

      # There's a target log because there's a recoverable log!
      assert process.tgt_log_id == log.log_id

      TOPHelper.top_stop(gateway)
    end

    test "starts the process (custom, local)" do
      gateway = ServerSetup.server!()

      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      # Add a recoverable log on the target server (which is the gateway)
      log = LogSetup.log!(server_id: gateway.server_id, forge_version: 50)

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id, own_server: true
        )

      params = %{method: :custom, log_id: log.log_id}
      meta = %{recover: recover, gateway: gateway, log: log}

      request = RequestHelper.mock_request(LogRecoverRequest, params, meta)

      assert {:ok, _request} = Requestable.handle_request(request, socket)

      assert [process] = ProcessQuery.get_processes_on_server(gateway.server_id)

      assert process.type == :log_recover_custom
      assert process.gateway_id == process.target_id
      assert process.src_file_id == recover.file_id
      refute process.src_connection_id
      assert process.data.recover_version == recover.modules.log_recover.version

      # Process is targeting the correct log
      assert process.tgt_log_id == log.log_id

      TOPHelper.top_stop(gateway)
    end

    test "starts the process (custom, remote)" do
      gateway = ServerSetup.server!()
      target = ServerSetup.server!()

      recover = SoftwareSetup.log_recover!(server_id: gateway.server_id)

      # Add a recoverable log to the target server
      log = LogSetup.log!(server_id: target.server_id, revisions: 2)

      socket =
        ChannelSetup.mock_server_socket(
          gateway_id: gateway.server_id,
          destination_id: target.server_id,
          real_connection?: true
        )

      params = %{method: :local, log_id: log.log_id}
      meta = %{recover: recover, gateway: gateway, log: log}

      request = RequestHelper.mock_request(LogRecoverRequest, params, meta)

      assert {:ok, _request} = Requestable.handle_request(request, socket)

      assert [process] = ProcessQuery.get_processes_on_server(gateway.server_id)

      assert process.type == :log_recover_custom
      assert process.target_id == target.server_id
      assert process.src_file_id == recover.file_id
      assert process.src_connection_id == socket.assigns.ssh.connection_id
      assert process.data.recover_version == recover.modules.log_recover.version

      # Targets the correct log
      assert process.tgt_log_id == log.log_id

      TOPHelper.top_stop(gateway)
    end
  end
end
