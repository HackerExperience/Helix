defmodule Helix.Test.Universe.Bank.Websocket.Requests.ChangePasswordTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Websocket.Requestable
  alias Helix.Universe.Bank.Query.Bank, as: BankQuery
  alias Helix.Universe.Bank.Websocket.Requests.ChangePassword,
    as: BankChangePasswordRequest

  alias Helix.Test.Channel.Request.Helper, as: RequestHelper
  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Process.TOPHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "BankChangePasswordRequest.check_permissions/2" do
    test "accepts when account belongs to player" do
      # Setups an Account socket and get gateway and entity
      # from related information.
      {socket, %{server: gateway, entity: entity}} =
        ChannelSetup.create_socket()

      # Setups a BankAccount for testing.
      bank_account =
        BankSetup.account!(owner_id: entity.entity_id)
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      # Creates the topic to join on bank channel.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Creates the payload for joining the bank channel.
      payload =
        %{
          "entity_id" => to_string(entity.entity_id),
          "password" => bank_account.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins the bank channel with the created BankAccount.
      {:ok, _bootstrap, bnk_socket} =
        join(socket, topic, payload)

      # Mocks a BankChangePasswordRequest that does not receive any parameters.
      request =
        RequestHelper.mock_request(BankChangePasswordRequest, %{})

      # Asserts that get permissions to continue with the request flow.
      assert {:ok, request} =
        Requestable.check_permissions(request, bnk_socket)

      # Asserts that meta contains the BankAccount which is necessary for
      # changing the BankAccount's password
      assert request.meta.bank_account == bank_account
    end

    test "rejects when account does not belongs to player" do
      # Setups an Account socket and get gateway and entity
      # from related information.
      {socket, %{server: gateway, entity: entity}} =
        ChannelSetup.create_socket()

      # Setups a BankAccount that not belongs to entity.
      bank_account =
        BankSetup.account!()
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      # Creates a bank channel topic based on BankAccount information.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Creates the payload for logging in the bank channel on created
      # BankAccount.
      payload =
        %{
          "entity_id" => to_string(entity.entity_id),
          "password" => bank_account.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins the bank channel.
      {:ok, _bootstrap, bnk_socket} =
        join(socket, topic, payload)

      # Mocks a BankChangePasswordRequest that does not receive any parameters.
      request =
        RequestHelper.mock_request(BankChangePasswordRequest, %{})

      # Asserts that get no permissions to change password because the entity
      # does not own the given BankAccount.
      assert {:error, reason, _} =
          Requestable.check_permissions(request, bnk_socket)

      # Asserts the reason for failing is "bank_account_not_belong".
      assert reason.message == "bank_account_not_belongs"
    end
  end

  describe "BankChangePasswordRequest.handle_request/2" do
    test "accepts if the password changes after process ends" do
      # Setups an Account socket and gets gateway and entity from
      # related information.
      {socket, %{server: gateway, entity: entity}} =
        ChannelSetup.create_socket()

      # Setups a BankAccount for testing.
      bank_account =
        BankSetup.account!(owner_id: entity.entity_id)
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      # Stores the old password on a variable to compare after the process.
      old_password = bank_account.password

      # Creates the topic used for logging in the bank channel.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Creates the payload used as parameters to log in on bank channel.
      payload =
        %{
          "entity_id" => to_string(entity.entity_id),
          "password" => bank_account.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins the bank channel.
      {:ok, _bootstrap, bnk_socket} =
        join(socket, topic, payload)

      # Mocks BankChangePasswordRequest that does not receive any parameters.
      request =
        RequestHelper.mock_request(BankChangePasswordRequest, %{})

      # Checks the permissions for given Entity on BankAccount.
      {:ok, request} =
        Requestable.check_permissions(request, bnk_socket)

      # Asserts that request is handled correctly.
      assert {:ok, request} =
        Requestable.handle_request(request, bnk_socket)

      # Gets the process' id for forcing it's termination.
      process_id = request.meta.process.process_id

      # Forces the process to complete.
      TOPHelper.force_completion(process_id)

      # Fetchs the BankAccount from the database.
      bank_account =
        BankQuery.fetch_account(
          bank_account.atm_id,
          bank_account.account_number
          )

      # Refutes if the current BankAccount password is equals
      # to the old_password.
      refute bank_account.password == old_password
    end
  end
end
