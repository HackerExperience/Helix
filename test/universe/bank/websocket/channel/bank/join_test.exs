defmodule Helix.Universe.Bank.Websocket.Channel.Bank.JoinTest do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Network.Setup.Bounce, as: BounceSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.Bank.Helper, as: BankHelper
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  @moduletag :driver

  describe "BankJoin" do
    test "can join a bank account with valid data" do
      {socket, %{account: player, server: gateway}} =
        ChannelSetup.create_socket()

      entity_id = socket.assigns.entity_id
      bounce = BounceSetup.bounce!(entity_id: entity_id)

      bank_account = BankSetup.account!()

      payload =
         %{
           "entity_id" => to_string(entity_id),
           "password" => bank_account.password,
           "gateway_id" => to_string(gateway.server_id),
           "bounce_id" => to_string(bounce.bounce_id)
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

      # `account` data is valid
      assert new_socket.assigns.account_id ==
        player.account_id

      # `gateway` data is valid
      assert new_socket.assigns.gateway.server_id == gateway.server_id

      # connection is being created
      assert Map.has_key?(new_socket.assigns, :tunnel)
      assert Map.has_key?(new_socket.assigns, :bank_login)

      # Socket related stuff
      assert new_socket.joined
      assert new_socket.topic == topic

      # It returned the bank account bootstrap
      assert bootstrap.data.balance
    end

    test "can not join with the wrong password" do
      {socket, %{server: gateway}} = ChannelSetup.create_socket()

      entity_id = socket.assigns.entity_id
      bounce = BounceSetup.bounce!(entity_id: entity_id)

      bank_account = BankSetup.account!()

      payload =
        %{
          "entity_id" => to_string(entity_id),
          "password" => BankHelper.password(),
          "gateway_id" => to_string(gateway.server_id),
          "bounce_id" => to_string(bounce.bounce_id)
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
      bounce = BounceSetup.bounce!(entity_id: entity_id)

      payload =
         %{
           "entity_id" => to_string(entity_id),
           "password" => BankHelper.password(),
           "gateway_id" => to_string(gateway.server_id),
           "bounce_id" => to_string(bounce.bounce_id)
          }

      atm_id = BankHelper.atm_id()
      account_number = BankHelper.account_number()

      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Try to join the channel
      assert {:error, reason} =
        join(socket, topic, payload)

      assert reason.data == "bank_account_not_found"
    end
    test "can not join with a not owned bounce" do
      {socket, %{server: gateway}} = ChannelSetup.create_socket()

      entity_id = socket.assigns.entity_id
      bounce = BounceSetup.bounce!()

      bank_account = BankSetup.account!()

      payload =
        %{
          "entity_id" => to_string(entity_id),
          "password" => bank_account.password,
          "gateway_id" => to_string(gateway.server_id),
          "bounce_id" => to_string(bounce.bounce_id)
        }

      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Try to join the channel
      assert {:error, reason} = join(socket, topic, payload)

      assert reason.data == "bounce_not_belongs"

    end
    test "can not join with a not owned gateway" do
      {socket, _} = ChannelSetup.create_socket()

      random_server = ServerSetup.server!()
      entity_id = socket.assigns.entity_id
      bounce = BounceSetup.bounce!(entity_id: entity_id)

      bank_account = BankSetup.account!()

      payload =
        %{
          "entity_id" => to_string(entity_id),
          "password" => bank_account.password,
          "gateway_id" => to_string(random_server.server_id),
          "bounce_id" => to_string(bounce.bounce_id)
        }

      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Try to join the channel
      assert {:error, reason} = join(socket, topic, payload)

      assert reason.data == "server_not_belongs"
    end
  end

end
