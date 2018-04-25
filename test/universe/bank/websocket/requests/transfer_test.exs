defmodule Helix.Test.Universe.Bank.Websocket.Requests.TransferTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Account.Query.Account, as: AccountQuery
  alias Helix.Websocket.Requestable
  alias Helix.Universe.Bank.Websocket.Requests.Transfer, as: BankTransferRequest

  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  @internet_id NetworkHelper.internet_id()

  describe "BankTransferRequest.check_params/2" do
    test "validates expected data" do
      # Setups an Account socket and gets the gateway
      # from the related information.
      {socket, %{server: gateway}} =
        ChannelSetup.create_socket()

      # Setups sending BankAccount.
      sending_acc = BankSetup.account!(balance: 600)
      atm_id = sending_acc.atm_id
      account_number = sending_acc.account_number

      # Setups receiving BankAccount.
      to_account = BankSetup.account!()

      # Gets ip for the receiving BankAccount's ATM.id.
      bank_ip = ServerHelper.get_ip(to_account.atm_id)

      # Gets entity id from the socket assigns.
      entity_id = socket.assigns.entity_id

      # Creates topic for connecting on bank channel.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Creates parameters for joining the bank channel.
      payload =
        %{
          "entity_id" => to_string(entity_id),
          "password" => sending_acc.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins the bank channel.
      {:ok, _bootstrap, bank_socket} =
        join(socket, topic, payload)

      # Creates parameters for BankTransferRequest.
      params =
        %{
          "to_acc" => to_account.account_number,
          "to_bank_net" => to_string(@internet_id),
          "to_bank_ip" => bank_ip,
          "password" => to_account.password,
          "amount" => 300
        }

      # Creates BankTransferRequest with parameters.
      request = BankTransferRequest.new(params)

      # Asserts that parameters are in the correct format.
      assert {:ok, _request} = Requestable.check_params(request, bank_socket)
    end
  end

  describe "BankTransferRequest.check_permissions/2" do
    test "accepts when everything is OK" do
      # Setups an Account socket and gets the related gateway.
      {socket, %{server: gateway}} =
        ChannelSetup.create_socket()

      # Gets the Entity related to the socket.
      entity_id = socket.assigns.entity_id

      # Setups the sending BankAccount.
      sending_acc = BankSetup.account!(balance: 600)
      atm_id = sending_acc.atm_id
      account_number = sending_acc.account_number

      # Setups the receiving BankAccount.
      to_account = BankSetup.account!()

      # Gets the Bank's ip and sets the amount to transfer.
      bank_ip = ServerHelper.get_ip(to_account.atm_id)
      amount = 300

      # Creates topic for connecting on bank channel.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Creates parameters for joining the bank channel.
      payload =
        %{
          "entity_id" => to_string(entity_id),
          "password" => sending_acc.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins bank channel.
      {:ok, _bootstrap, bnk_socket} =
        join(socket, topic, payload)

      # Gets the player's account_id from socket.
      account_id = bnk_socket.assigns.account_id

      # Creates parameters for the request.
      params =
        %{
          bank_account: to_account.account_number,
          bank_ip: bank_ip,
          bank_net: @internet_id,
          password: sending_acc.password,
          amount: amount
        }

      # Mocks the BankTransferRequest pasing parameters.
      request = RequestHelper.mock_request(BankTransferRequest, params)

      # Asserts that request passes on permission test.
      assert {:ok, request} = Requestable.check_permissions(request, bnk_socket)

      # Asserts that meta fields are all valid.
      assert request.meta.to_account == to_account
      assert request.meta.from_account == sending_acc
      assert request.meta.amount == amount
      assert request.meta.started_by == AccountQuery.fetch(account_id)
      assert request.meta.gateway == gateway
    end
  end

  describe "BankTransferRequest.handle_request/2" do
    test "starts the process" do
      # Setups an Account socket and gets related gateway.
      {socket, %{server: gateway}} =
        ChannelSetup.create_socket()

      # Gets entity_id from socket.
      entity_id = socket.assigns.entity_id

      # Setups sending BankAccount.
      sending_acc = BankSetup.account!(balance: 600)
      atm_id = sending_acc.atm_id
      account_number = sending_acc.account_number

      # Setups receiving BankAccount.
      to_account = BankSetup.account!()

      # Gets receiving BankAccount's ATM ip.
      bank_ip = ServerHelper.get_ip(to_account.atm_id)

      # Sets the amount to be tranfered.
      amount = 300

      # Creates topic for connecting on bank channel.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Creates the parameters for joining bank channel.
      payload =
        %{
          "entity_id" => to_string(entity_id),
          "password" => sending_acc.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins bank channel.
      {:ok, _bootstrap, bnk_socket} =
        join(socket, topic, payload)

      # Create parameters to request.
      params =
        %{
          bank_account: to_account.account_number,
          bank_ip: bank_ip,
          bank_net: @internet_id,
          password: sending_acc.password,
          amount: amount
        }

      # Mocks BankTranferRequest.
      request = RequestHelper.mock_request(BankTransferRequest, params)

      # Checks permissions to the player do the tranfer.
      {:ok, request} = Requestable.check_permissions(request, bnk_socket)

      # Asserts that request is handled correctly.
      assert {:ok, request} = Requestable.handle_request(request, bnk_socket)

      # Asserts that process has been created.
      assert request.meta.process

      TOPHelper.top_stop(gateway)
    end
  end
end
