defmodule Helix.Test.Universe.Bank.Websocket.Requests.RevealPassword do

  use Helix.Test.Case.Integration

  import Phoenix.ChannelTest

  alias Helix.Websocket.Requestable
  alias Helix.Universe.Bank.Websocket.Requests.RevealPassword,
    as: BankRevealPasswordRequest

  alias Helix.Test.Channel.Helper, as: ChannelHelper
  alias Helix.Test.Channel.Setup, as: ChannelSetup
  alias Helix.Test.Universe.Bank.Setup, as: BankSetup

  describe "BankRevealPasswordRequest.check_params/2" do
    test "accepts when token is in valid format" do
      {socket, %{server: gateway, entity: entity}} =
        ChannelSetup.create_socket()

      # Create a Expiration date for the token that will expire
      # in 5 minutes.
      expiration =
        DateTime.utc_now()
        |> DateTime.to_unix(:second)
        |> Kernel.+(60 * 5)
        |> DateTime.from_unix!(:second)

      # Create Bank Account and get it's information.
      bank_account = BankSetup.account!()
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      # Create the topic to log in the bank channel.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Create a token with signied to previous created bank account
      # and expiration date.
      {token, _} =
        BankSetup.token(acc: bank_account, expiration_date: expiration)

      # Create the payload which will be used to join the bank channel.
      payload =
        %{
          "entity_id" => to_string(entity.entity_id),
          "password" => bank_account.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins the bank channel.
      {:ok, _bootstrap, bnk_socket} =
        join(socket, topic, payload)

      params =
        %{
          "token" => token.token_id
        }

      # Creates a BankRevealPasswordRequest.
      request = BankRevealPasswordRequest.new(params)

      assert {:ok, request} =
        Requestable.check_params(request, bnk_socket)

      # Check if token.id still the same as before after checking.
      assert request.params.token == token.token_id
    end
  end

  describe "BankRevealPasswordRequest.check_perimssions/2" do
    test "accepts when token exists and belongs to bank account" do
      {socket, %{server: gateway, entity: entity}} =
        ChannelSetup.create_socket()

      # Create a Expiration date for the token that will expire
      # in 5 minutes.
      expiration =
        DateTime.utc_now()
        |> DateTime.to_unix(:second)
        |> Kernel.+(60 * 5)
        |> DateTime.from_unix!(:second)

      # Create Bank Account and get it's information.
      bank_account = BankSetup.account!()
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      # Create the topic to log in the bank channel.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Create a token with signied to previous created bank account
      # and expiration date.
      {token, _} =
        BankSetup.token(acc: bank_account, expiration_date: expiration)

      # Create the payload which will be used to join the bank channel.
      payload =
        %{
          "entity_id" => to_string(entity.entity_id),
          "password" => bank_account.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins the bank channel.
      {:ok, _bootstrap, bnk_socket} =
        join(socket, topic, payload)

      params =
        %{
          "token" => token.token_id
        }

      # Creates a BankRevealPasswordRequest.
      request = BankRevealPasswordRequest.new(params)

      {:ok, request} =
        Requestable.check_params(request, bnk_socket)

      assert {:ok, request} =
        Requestable.check_permissions(request, bnk_socket)

      # Checks if token information is correct.
      assert request.meta.token.atm_id == token.atm_id
      assert request.meta.token.token_id == token.token_id
      assert request.meta.token.account_number == token.account_number
    end
  end

  describe "BankRevealPasswordRequest.handle_request/2" do
    test "creates reveal password process" do
      {socket, %{server: gateway, entity: entity}} =
        ChannelSetup.create_socket()

      # Create a Expiration date for the token that will expire
      # in 5 Minutes.
      expiration =
        DateTime.utc_now()
        |> DateTime.to_unix(:second)
        |> Kernel.+(60 * 5)
        |> DateTime.from_unix!(:second)

      # Create Bank Account and get it's information.
      bank_account = BankSetup.account!()
      atm_id = bank_account.atm_id
      account_number = bank_account.account_number

      # Create the topic to log in the bank channel.
      topic = ChannelHelper.bank_topic_name(atm_id, account_number)

      # Create a token with signied to previous created bank account
      # and expiration date.
      {token, _} =
        BankSetup.token(acc: bank_account, expiration_date: expiration)

      # Create the payload which will be used to join the bank channel.
      payload =
        %{
          "entity_id" => to_string(entity.entity_id),
          "password" => bank_account.password,
          "gateway_id" => to_string(gateway.server_id)
        }

      # Joins the bank channel.
      {:ok, _bootstrap, bnk_socket} =
        join(socket, topic, payload)

      params =
        %{
          "token" => token.token_id
        }

      # Creates a BankRevealPasswordRequest.
      request = BankRevealPasswordRequest.new(params)

      # Checks if params isn't invalid.
      {:ok, request} =
        Requestable.check_params(request, bnk_socket)

      # Checks if token exists and is assigned to the correct account.
      {:ok, request} =
        Requestable.check_permissions(request, bnk_socket)

      assert {:ok, request} =
        Requestable.handle_request(request, bnk_socket)

      # Checks if process information is correct.
      assert request.meta.process
      assert request.meta.process.type == :bank_reveal_password
      assert request.meta.process.data.atm_id == bank_account.atm_id
      assert request.meta.process.data.account_number ==
        bank_account.account_number
    end
  end
end
