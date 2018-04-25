defmodule Helix.Test.Universe.Bank.Websocket.Requests.BootstrapTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Universe.Bank.Websocket.Requests.Bootstrap,
  as: BankBootstrapRequest
  alias Helix.Websocket.Requestable

  alias Helix.Test.Universe.Bank.Setup, as: BankSetup
  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup

  describe "BankBootstrapRequest.handle_request/2" do
    test "bootstrap" do
      # Setups an Account socket.
      {socket, %{entity: entity, server: gateway}} =
        ChannelSetup.create_socket()

      # Setups a BankAccount.
      bank_acc = BankSetup.account!(balance: BankHelper.amount)
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

      # Mocks a BankBootstrapRequest.
      request =
        BankBootstrapRequest.new(%{})

      # Request Checking Parameters (which does not exists in this case).
      {:ok, request} =
        Requestable.check_params(request, bnk_socket)

      # Request Checking Permissions (which does nothing in this case
      # because receives no parameters and is already logged in the
      # Bank channel).
      {:ok, request} =
        Requestable.check_permissions(request, bnk_socket)

      # Asserts that request has been handled successfully.
      assert {:ok, request} =
        Requestable.handle_request(request, bnk_socket)

      # Asserts that bootstrap information is correct.
      assert request.meta.bootstrap
      assert request.meta.bootstrap.balance == bank_acc.balance
    end
  end
end
