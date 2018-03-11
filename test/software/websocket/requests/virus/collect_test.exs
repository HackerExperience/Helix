defmodule Helix.Software.Websocket.Requests.Virus.CollectTest do

  use Helix.Test.Case.Integration

  alias Helix.Websocket.Requestable
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Software.Websocket.Requests.Virus.Collect, as: VirusCollectRequest

  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @mock_socket ChannelSetup.mock_account_socket()

  describe "check_params/2" do
    test "validates and casts expected data" do
      gateway_id = ServerSetup.id()
      file1_id = SoftwareSetup.id()
      file2_id = SoftwareSetup.id()
      bounce_id = NetworkHelper.bounce_id()
      atm_id = BankHelper.atm_id()
      account_number = BankHelper.account_number()
      wallet = nil  # 244

      params =
        %{
          "gateway_id" => to_string(gateway_id),
          "viruses" => [to_string(file1_id), to_string(file2_id)],
          "bounce_id" => to_string(bounce_id),
          "atm_id" => to_string(atm_id),
          "account_number" => account_number,
          "wallet" => wallet
        }

      request = VirusCollectRequest.new(params)

      assert {:ok, request} = Requestable.check_params(request, @mock_socket)

      assert request.params.gateway_id == gateway_id
      assert request.params.bounce_id == bounce_id
      assert request.params.atm_id == atm_id
      assert request.params.account_number == account_number
      assert request.params.viruses == [file1_id, file2_id]
      assert request.params.wallet == wallet
    end

    test "rejects when invalid data is given" do
      gateway_id = ServerSetup.id()
      file1_id = SoftwareSetup.id()
      file2_id = SoftwareSetup.id()
      bounce_id = NetworkHelper.bounce_id()
      atm_id = BankHelper.atm_id()
      account_number = BankHelper.account_number()
      wallet = nil  # 244

      base_params =
        %{
          "gateway_id" => to_string(gateway_id),
          "viruses" => [to_string(file1_id), to_string(file2_id)],
          "bounce_id" => to_string(bounce_id),
          "atm_id" => to_string(atm_id),
          "account_number" => account_number,
          "wallet" => wallet
        }

      # Missing `gateway_id`
      p0 = Map.drop(base_params, ["gateway_id"])

      # Missing `viruses`
      p1 = Map.drop(base_params, ["viruses"])

      # Missing valid payment information
      p2 = Map.drop(base_params, ["atm_id", "account_number", "wallet"])

      # Partial bank account data
      p3 = Map.drop(base_params, ["atm_id"])

      # Invalid entry at `viruses`
      p4 = Map.replace!(base_params, "viruses", ["lol", to_string(file2_id)])

      # Viruses must not be empty
      p5 = Map.replace!(base_params, "viruses", [])

      req0 = VirusCollectRequest.new(p0)
      req1 = VirusCollectRequest.new(p1)
      req2 = VirusCollectRequest.new(p2)
      req3 = VirusCollectRequest.new(p3)
      req4 = VirusCollectRequest.new(p4)
      req5 = VirusCollectRequest.new(p5)

      assert {:error, reason0, _} = Requestable.check_params(req0, @mock_socket)
      assert {:error, reason1, _} = Requestable.check_params(req1, @mock_socket)
      assert {:error, reason2, _} = Requestable.check_params(req2, @mock_socket)
      assert {:error, reason3, _} = Requestable.check_params(req3, @mock_socket)
      assert {:error, reason4, _} = Requestable.check_params(req4, @mock_socket)
      assert {:error, reason5, _} = Requestable.check_params(req5, @mock_socket)

      assert reason0 == %{message: "bad_request"}
      assert reason1 == reason0
      assert reason2 == reason1
      assert reason3 == reason2
      assert reason5 == reason3

      assert reason4 == %{message: "bad_virus"}
    end
  end

  describe "check_permissions/2" do
    test "accepts when data is valid" do
      {gateway, %{entity: entity}} = ServerSetup.server()

      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      bounce = NetworkSetup.Bounce.bounce!(entity_id: entity.entity_id)
      bank_account = BankSetup.account!(owner_id: entity.entity_id)

      {virus1, %{file: file1}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      {virus2, %{file: file2}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      params =
        %{
          gateway_id: gateway.server_id,
          viruses: [file1.file_id, file2.file_id],
          bounce_id: bounce.bounce_id,
          atm_id: bank_account.atm_id,
          account_number: bank_account.account_number,
          wallet: nil
        }

      request = RequestHelper.mock_request(VirusCollectRequest, params)

      assert {:ok, request} = Requestable.check_permissions(request, socket)

      assert request.meta.gateway == gateway
      assert request.meta.payment_info == {bank_account, nil}
      assert request.meta.bounce == bounce
      assert [
        %{file: file1, virus: virus1},
        %{file: file2, virus: virus2},
      ] == request.meta.viruses
    end

    test "rejects when bad things happen" do
      # NOTE: Aggregating several test into one to avoid recreating heavy stuff
      {gateway, %{entity: entity}} = ServerSetup.server()
      {server, _} = ServerSetup.server()

      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      {_virus1, %{file: file1}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      {_virus2, %{file: file2}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      {_, %{file: inactive}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: false,
          real_file?: true
        )

      gateway_storage_id = SoftwareHelper.get_storage_id(gateway)
      cracker = SoftwareSetup.cracker!(storage_id: gateway_storage_id)

      bounce = NetworkSetup.Bounce.bounce!(entity_id: entity.entity_id)
      bad_bounce = NetworkSetup.Bounce.bounce!()

      bank_account = BankSetup.account!(owner_id: entity.entity_id)
      bad_account = BankSetup.account!(atm_id: bank_account.atm_id)

      base_params =
        %{
          gateway_id: gateway.server_id,
          viruses: [file1.file_id, file2.file_id],
          bounce_id: bounce.bounce_id,
          atm_id: bank_account.atm_id,
          account_number: bank_account.account_number,
          wallet: nil
        }

      ### Test 0: `gateway_id` is not owned by the entity
      p0 = Map.replace!(base_params, :gateway_id, server.server_id)
      req0 = RequestHelper.mock_request(VirusCollectRequest, p0)

      assert {:error, reason, _} = Requestable.check_permissions(req0, socket)
      assert reason == %{message: "server_not_belongs"}

      ### Test 1: BankAccount is not owned by the entity
      p1 =
        Map.replace!(base_params, :account_number, bad_account.account_number)
      req1 = RequestHelper.mock_request(VirusCollectRequest, p1)

      assert {:error, reason, _} = Requestable.check_permissions(req1, socket)
      assert reason == %{message: "bank_account_not_belongs"}

      ### Test 2: Bounce may not be used
      p2 = Map.replace!(base_params, :bounce_id, bad_bounce.bounce_id)
      req2 = RequestHelper.mock_request(VirusCollectRequest, p2)

      assert {:error, reason, _} = Requestable.check_permissions(req2, socket)
      assert reason == %{message: "bounce_not_belongs"}

      ### Test 3: A cracker is not a virus!
      p3 = Map.replace!(base_params, :viruses, [file1.file_id, cracker.file_id])
      req3 = RequestHelper.mock_request(VirusCollectRequest, p3)

      assert {:error, reason, _} = Requestable.check_permissions(req3, socket)
      assert reason == %{message: "virus_not_found"}

      ### Test 4: Collecting from a virus that is not active
      p4 =
        Map.replace!(base_params, :viruses, [file1.file_id, inactive.file_id])
      req4 = RequestHelper.mock_request(VirusCollectRequest, p4)

      assert {:error, reason, _} = Requestable.check_permissions(req4, socket)
      assert reason == %{message: "virus_not_active"}

      ### Test 5: Missing payment information
      # TODO #244
    end
  end

  describe "handle_request/2" do
    test "starts collect" do
      {gateway, %{entity: entity}} = ServerSetup.server()

      socket =
        ChannelSetup.mock_account_socket(
          connect_opts: [entity_id: entity.entity_id]
        )

      {virus1, %{file: file1}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      {virus2, %{file: file2}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity.entity_id,
          is_active?: true,
          real_file?: true
        )

      bounce = NetworkSetup.Bounce.bounce!(entity_id: entity.entity_id)
      bank_account = BankSetup.account!(owner_id: entity.entity_id)

      params =
        %{
          gateway_id: gateway.server_id,
          viruses: [file1.file_id, file2.file_id],
          bounce_id: bounce.bounce_id,
          atm_id: bank_account.atm_id,
          account_number: bank_account.account_number,
          wallet: nil
        }

      meta =
        %{
          gateway: gateway,
          payment_info: {bank_account, nil},
          bounce: bounce,
          viruses: [
            %{file: file1, virus: virus1}, %{file: file2, virus: virus2}
          ]
        }

      request = RequestHelper.mock_request(VirusCollectRequest, params, meta)

      # There's nothing we can do with the response because it's async
      assert {:ok, _} = Requestable.handle_request(request, socket)

      # So let's make sure the processes were created
      processes = ProcessQuery.get_processes_on_server(gateway)

      process1 = Enum.find(processes, &(&1.src_file_id == file1.file_id))
      process2 = Enum.find(processes, &(&1.src_file_id == file2.file_id))

      assert process1.gateway_id == gateway.server_id
      assert process1.source_entity_id == entity.entity_id
      assert process1.src_connection_id
      assert process1.src_file_id == file1.file_id
      assert process1.bounce_id == bounce.bounce_id
      assert process1.tgt_atm_id == bank_account.atm_id
      assert process1.tgt_acc_number == bank_account.account_number
      refute process1.data.wallet

      assert process2.gateway_id == gateway.server_id
      assert process2.source_entity_id == entity.entity_id
      assert process2.src_connection_id
      assert process2.src_file_id == file2.file_id
      assert process2.bounce_id == bounce.bounce_id
      assert process2.tgt_atm_id == bank_account.atm_id
      assert process2.tgt_acc_number == bank_account.account_number
      refute process2.data.wallet

      TOPHelper.top_stop()
    end
  end
end
