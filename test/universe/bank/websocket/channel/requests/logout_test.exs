defmodule Helix.Test.Universe.Bank.Websocket.Requests.LogoutTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "bootstrap" do
    test "returns expected result" do
      # Setups an Account socket.
      {socket, %{entity: entity, server: gateway}} =
        ChannelSetup.create_socket()

      # Setups a BankAccount.
      bank_acc = BankSetup.account!()
      atm_id = bank_acc.atm_id
      account_number = bank_acc.account_number

      # Creates topic to log in the bank channel.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Create the payload which will be used to join the bank channel.
      payload =
        %{
          "entity_id" => to_string(entity.entity_id),
          "password" => bank_acc.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins the bank channel.
      {:ok, _bootstrap, bnk_socket} =
        join(socket, topic, payload)

      # Request logout
      push bnk_socket, "bank.logout", %{}

      # Wait process teardown. Required
      :timer.sleep(50)

      # Channel no longer exists
      refute Process.alive? bnk_socket.channel_pid
    end
  end
end
