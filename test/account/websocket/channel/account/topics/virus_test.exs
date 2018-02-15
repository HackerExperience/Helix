defmodule Helix.Account.Websocket.Channel.Account.Topics.VirusTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest
  import Helix.Test.Macros
  import Helix.Test.Channel.Macros

  alias Helix.Process.Query.Process, as: ProcessQuery

  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  describe "virus.collect" do
    test "starts a VirusCollectProcess on all active viruses" do
      {socket, %{entity_id: entity_id}} = ChannelSetup.join_account()
      {gateway, _} = ServerSetup.server(entity_id: entity_id)

      # Subscribe to the `server` channel, as `ProcessCreateEvents` go there
      ChannelSetup.join_server(
        own_server: true, gateway_id: gateway.server_id, socket: socket
      )

      {_virus1, %{file: file1}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity_id,
          is_active?: true,
          real_file?: true
        )

      {_virus2, %{file: file2}} =
        SoftwareSetup.Virus.virus(
          entity_id: entity_id,
          is_active?: true,
          real_file?: true
        )

      bounce = NetworkSetup.Bounce.bounce!(entity_id: entity_id)
      bank_account = BankSetup.account!(owner_id: entity_id)
      wallet = nil  # #244

      params =
        %{
          "gateway_id" => to_string(gateway.server_id),
          "viruses" => [to_string(file1.file_id), to_string(file2.file_id)],
          "bounce_id" => to_string(bounce.bounce_id),
          "atm_id" => to_string(bank_account.atm_id),
          "account_number" => bank_account.account_number,
          "wallet" => wallet
        }

      ref = push socket, "virus.collect", params
      assert_reply ref, :ok, %{}, timeout(:slow)

      # Client got the `process_created` events
      [process_created1, process_created2] =
        wait_events [:process_created, :process_created]

      assert process_created1.data.type == "virus_collect"
      assert process_created2.data.type == "virus_collect"

      assert [proc1, proc2] = ProcessQuery.get_processes_on_server(gateway)

      # Processes are valid!
      assert proc1.src_file_id == file1.file_id
      assert proc2.src_file_id == file2.file_id

      TOPHelper.top_stop()
    end
  end
end
