defmodule Helix.Universe.Bank.Websocket.Channel.Bank.JoinTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias HELL.TestHelper.Random
  alias Helix.Test.Cache.Helper, as: CacheHelper
  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  @moduletag :driver

  @internet_id NetworkHelper.internet_id()

  describe "BankJoin" do
    test "can join a bank account with valid data" do
      {socket, %{server: gateway}} = ChannelSetup.create_socket()

      entity_id = socket.assigns.entity_id

      {bank_account, _} = BankSetup.account()

      payload =
         %{
           "entity_id" => to_string(entity_id),
           "password" => bank_account.password
          }

      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Joins the channel
      assert {:ok, bootstrap, new_socket} = join(socket, topic, payload)

      # `atm_id` and `account_number` are valid
      assert new_socket.assigns.atm_id == atm_id
      assert new_socket.assigns.account_number == account_number

      # `entity` data is valid
      assert new_socket.assigns.entity_id == entity_id

      # Socket related stuff
      assert new_socket.joined
      assert new_socket.topic == topic

      # It returned the bank account bootstrap
      assert bootstrap.data.balance
    end

    test "can not join with the wrong password" do
      {socket, %{server: gateway}} = ChannelSetup.create_socket()

      entity_id = socket.assigns.entity_id

      {bank_account, _} = BankSetup.account()

      payload =
         %{
           "entity_id" => to_string(entity_id),
           "password" => BankHelper.password()
          }

      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Try to join the channel
      assert {:error, reason} = join(socket, topic, payload)

      assert reason.data == "password_invalid"
    end

    test "can not join with an account that does not exist" do
      {socket, %{server: gateway}} = ChannelSetup.create_socket()

      entity_id = socket.assigns.entity_id

      payload =
         %{
           "entity_id" => to_string(entity_id),
           "password" => BankHelper.password()
          }

      atm_id = BankHelper.atm_id()
      account_number = BankHelper.account_number()

      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Try to join the channel
      assert {:error, reason} =
        join(socket, topic, payload)

      assert reason.data == "bank_account_not_found"
    end
  end

end
