defmodule Helix.Test.Features.Virus.CollectTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros

  alias Helix.Network.Query.Tunnel, as: TunnelQuery
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Software.Model.Virus
  alias Helix.Software.Query.Virus, as: VirusQuery
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  @moduletag :feature

  describe "virus.collect" do
    # NOTE: Install lifecycle tested at `File.InstallTest`
    test "collect lifecycle" do
      {socket, %{entity_id: entity_id}} = ChannelSetup.join_account()
      {gateway, _} = ServerSetup.server(entity_id: entity_id)

      # Subscribe to the `server` channel, as `ProcessCreatedEvent`s go there
      ChannelSetup.join_server(
        own_server: true, gateway_id: gateway.server_id, socket: socket
      )

      {virus1, %{file: file1}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity_id,
          is_active?: true,
          real_file?: true,
          running_time: 600
        )

      {virus2, %{file: file2}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity_id,
          is_active?: true,
          real_file?: true,
          running_time: 6000
        )

      bounce = NetworkSetup.Bounce.bounce!(entity_id: entity_id)
      bank_acc = BankSetup.account!(owner_id: entity_id, balance: :random)
      wallet = nil  # #244

      params =
        %{
          "gateway_id" => to_string(gateway.server_id),
          "viruses" => [to_string(file1.file_id), to_string(file2.file_id)],
          "bounce_id" => to_string(bounce.bounce_id),
          "atm_id" => to_string(bank_acc.atm_id),
          "account_number" => bank_acc.account_number,
          "wallet" => wallet,
          "request_id" => RequestHelper.id()
        }

      # Request to collect the earnings of `virus1` and `virus2`
      ref = push socket, "virus.collect", params
      assert_reply ref, :ok, response, timeout(:slow)

      # Installation is acknowledge (`:ok`). Contains the `request_id`.
      assert response.meta.request_id == params["request_id"]
      assert response.data == %{}

      # After a while, client receives the new process through top recalque
      [process_created1, process_created2] =
        wait_events [:process_created, :process_created]

      # Notifications seem OK
      assert process_created1.data.type == "virus_collect"
      assert process_created1.meta.request_id == params["request_id"]
      assert process_created2.data.type == "virus_collect"
      assert process_created2.meta.request_id == params["request_id"]

      # Ensure that both processes were created
      processes = ProcessQuery.get_processes_on_server(gateway)
      process1 = Enum.find(processes, &(&1.src_file_id == file1.file_id))
      process2 = Enum.find(processes, &(&1.src_file_id == file2.file_id))

      # Process 1 is OK
      assert process1.gateway_id == gateway.server_id
      assert process1.source_entity_id == entity_id
      assert process1.src_connection_id
      assert process1.src_file_id == file1.file_id
      assert process1.bounce_id == bounce.bounce_id
      assert process1.tgt_atm_id == bank_acc.atm_id
      assert process1.tgt_acc_number == bank_acc.account_number
      refute process1.data.wallet

      # Process 2 is OK
      assert process2.gateway_id == gateway.server_id
      assert process2.source_entity_id == entity_id
      assert process2.src_connection_id
      assert process2.src_file_id == file2.file_id
      assert process2.bounce_id == bounce.bounce_id
      assert process2.tgt_atm_id == bank_acc.atm_id
      assert process2.tgt_acc_number == bank_acc.account_number
      refute process2.data.wallet

      # Make sure the connections were created as well
      connection1 = TunnelQuery.fetch_connection(process1.src_connection_id)
      tunnel1 = TunnelQuery.fetch_from_connection(connection1)

      # Connection has the right type
      assert connection1.connection_type == :virus_collect

      # Underlying tunnel was created and it only contains `virus_collect` conn
      assert tunnel1.bounce == bounce
      assert [connection1] == TunnelQuery.get_connections(tunnel1)

      # Same for `file2`...
      connection2 = TunnelQuery.fetch_connection(process2.src_connection_id)
      tunnel2 = TunnelQuery.fetch_from_connection(connection2)

      # Connection has the right type
      assert connection2.connection_type == :virus_collect

      # Underlying tunnel was created and it only contains `virus_collect` conn
      assert tunnel2.bounce == bounce
      assert [connection2] == TunnelQuery.get_connections(tunnel2)

      expected_earnings1 = Virus.calculate_earnings(file1, virus1, [])
      expected_earnings2 = Virus.calculate_earnings(file2, virus2, [])

      # Now we'll complete the first process
      TOPHelper.force_completion(process1)

      [process_completed, virus_collected, bank_account_updated] =
        wait_events [
          :process_completed, :virus_collected, :bank_account_updated
        ]

      # Ensure `process_id` trail on events
      assert process_completed.meta.process_id ==
        virus_collected.meta.process_id
      assert virus_collected.meta.process_id ==
        bank_account_updated.meta.process_id

      # Ensure `VirusCollectedEvent` is OK
      assert virus_collected.data.atm_id == to_string(bank_acc.atm_id)
      assert virus_collected.data.account_number == bank_acc.account_number
      assert virus_collected.data.money == expected_earnings1
      assert virus_collected.data.file_id == to_string(file1.file_id)

      # Ensure `BankAccountUpdatedEvent` is OK
      assert bank_account_updated.data.atm_id == to_string(bank_acc.atm_id)
      assert bank_account_updated.data.account_number == bank_acc.account_number
      assert bank_account_updated.data.password == bank_acc.password
      assert bank_account_updated.data.reason == "balance"

      # Same should happen with the second process
      TOPHelper.force_completion(process2)

      [process_completed, virus_collected, bank_account_updated] =
        wait_events [
          :process_completed, :virus_collected, :bank_account_updated
        ]

      # Ensure `process_id` trail on events
      assert process_completed.meta.process_id ==
        virus_collected.meta.process_id
      assert virus_collected.meta.process_id ==
        bank_account_updated.meta.process_id

      # Ensure `VirusCollectedEvent` is OK
      assert virus_collected.data.atm_id == to_string(bank_acc.atm_id)
      assert virus_collected.data.account_number == bank_acc.account_number
      assert virus_collected.data.money == expected_earnings2
      assert virus_collected.data.file_id == to_string(file2.file_id)

      # Ensure `BankAccountUpdatedEvent` is OK
      assert bank_account_updated.data.atm_id == to_string(bank_acc.atm_id)
      assert bank_account_updated.data.account_number == bank_acc.account_number
      assert bank_account_updated.data.password == bank_acc.password
      assert bank_account_updated.data.reason == "balance"

      # BankAccount had its balance updated
      new_bank_acc =
        BankQuery.fetch_account(bank_acc.atm_id, bank_acc.account_number)

      assert new_bank_acc.balance ==
        bank_acc.balance + expected_earnings1 + expected_earnings2

      # Both viruses had their `running_time` reset to 0
      # (returning 1 or 2 is OK because slower systems (travis))
      new_virus1 = VirusQuery.fetch(file1.file_id)
      assert_in_delta new_virus1.running_time, 0, 2.01
      assert new_virus1.is_active?

      new_virus2 = VirusQuery.fetch(file2.file_id)
      assert_in_delta new_virus2.running_time, 0, 2.01
      assert new_virus2.is_active?

      # Processes no longer exist
      assert Enum.empty?(ProcessQuery.get_processes_on_server(gateway))

      # TODO: #388
      # Underlying connections and tunnels no longer exist as well
      # refute TunnelQuery.fetch_connection(process1.src_connection_id)
      # refute TunnelQuery.fetch_from_connection(connection1)
      # refute TunnelQuery.fetch_connection(process2.src_connection_id)
      # refute TunnelQuery.fetch_from_connection(connection2)

      TOPHelper.top_stop()
    end
  end
end
