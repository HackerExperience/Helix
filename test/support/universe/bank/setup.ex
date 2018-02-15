defmodule Helix.Test.Universe.Bank.Setup do

  alias Helix.Account.Model.Account
  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Network.Model.Connection
  alias Helix.Universe.Bank.Action.Flow.BankAccount, as: BankAccountFlow
  alias Helix.Universe.Bank.Action.Flow.BankTransfer, as: BankTransferFlow
  alias Helix.Universe.Bank.Internal.BankTransfer, as: BankTransferInternal
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankToken
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Repo, as: UniverseRepo

  alias Helix.Test.Account.Setup, as: AccountSetup
  alias Helix.Test.Network.Setup, as: NetworkSetup
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Universe.NPC.Helper, as: NPCHelper
  alias Helix.Test.Universe.Bank.Helper, as: BankHelper

  @doc """
  See doc on `fake_account/1`
  """
  def account(opts \\ []) do
    {account, related} = fake_account(opts)
    {:ok, inserted} = UniverseRepo.insert(account)

    {inserted, related}
  end

  def account!(opts \\ []) do
    {account, _} = account(opts)
    account
  end

  @doc """
  - atm_id: generated account will belong to that atm
  - atm_seq: alternative to `atm_id`, when you don't care about the ID but you
    care that the resulting atm is constant. For instance, atm on atm_seq=1 is
    different from atm on atm_seq=2
  - owner_id: Player who owns that account. It's OK to pass an Entity.ID
  - balance: Starting balance of that account. Defaults to 0
  - number: Bank account number.
  """
  def fake_account(opts \\ []) do
    {bank, _} = NPCHelper.bank()

    atm_id =
      cond do
        opts[:atm_seq] ->
          Enum.fetch!(bank.servers, opts[:atm_seq] - 1).id
        opts[:atm_id] ->
          opts[:atm_id]
        true ->
          Enum.random(bank.servers).id
      end

    # Handle the case when user passes an entity id
    owner_id =
      case opts[:owner_id] do
        %Entity.ID{id: entity_id} ->
          %Account.ID{id: entity_id}
        account_id = %{} ->
          account_id
        nil ->
          Account.ID.generate()
      end

    number = Keyword.get(opts, :number, BankHelper.account_number())
    balance = Keyword.get(opts, :balance, 0)

    acc =
      %BankAccount{
        account_number: number,
        balance: balance,
        bank_id: bank.id,
        atm_id: atm_id,
        password: "secret",
        owner_id: owner_id,
        creation_date: DateTime.utc_now()
      }

    {acc, %{}}
  end

  @doc """
  See doc on `fake_transfer/1`
  """
  def transfer(opts \\ []) do
    {transfer, related = %{acc1: acc1, acc2: acc2}} = fake_transfer(opts)

    {:ok, inserted} =
      BankTransferInternal.start(
        acc1, acc2, transfer.amount, transfer.started_by
      )

    {inserted, related}
  end

  @doc """
  - transfer_id: Force the transfer to have this id.
  - amount: Specify transfer amount. Defaults to a random number.
  - acc1: account from (BankAccount.t)
  - acc2: account to (BankAccount.t)
  - balance1: Balance on acc1 (See note 1)
  - balance2: Balance on acc2 (See note 1)

  Related data: acc1 :: BankAccount.t, acc2 :: BankAccount.t

  [1] - If `acc1` or `acc2` are specified, `balance1` and `balance2` are
  ignored, respectively.
  """
  def fake_transfer(opts \\ []) do
    amount = Keyword.get(opts, :amount, BankHelper.amount())
    balance1 = Keyword.get(opts, :balance1, amount)
    balance2 = Keyword.get(opts, :balance2, 0)

    acc1 =
      if opts[:acc1] do
        opts[:acc1]
      else
        account!([balance: balance1])
      end

    acc2 =
      if opts[:acc2] do
        opts[:acc2]
      else
        account!([balance: balance2])
      end

    started_by = Account.ID.generate()

    transfer_id = Keyword.get(opts, :transfer_id, BankTransfer.ID.generate())

    transfer =
      %BankTransfer{
        transfer_id: transfer_id,
        account_from: acc1.account_number,
        account_to: acc2.account_number,
        atm_from: acc1.atm_id,
        atm_to: acc2.atm_id,
        amount: amount,
        started_by: started_by,
        started_time: DateTime.utc_now()
      }

    {transfer, %{acc1: acc1, acc2: acc2}}
  end

  @doc """
  See doc on `fake_token/1`
  """
  def token(opts \\ []) do
    {token, related} = fake_token(opts)
    {:ok, inserted} = UniverseRepo.insert(token)

    {inserted, related}
  end

  @doc """
  - acc: Associate that account to the token (BankAccount.t)
  - connection_id: Specify the connection ID.
  - expired: Whether the generated token should be expired or not.

  Related data: BankAccount.t
  """
  def fake_token(opts \\ []) do
    connection_id = Keyword.get(opts, :connection_id, Connection.ID.generate())
    acc =
      if opts[:acc] do
        opts[:acc]
      else
        account!()
      end

    token_id =
      if opts[:token_id] do
        opts[:token_id]
      else
        Ecto.UUID.generate()
      end

    # TODO utisl
    expiration_date =
      if opts[:expired] do
        DateTime.utc_now()
        |> DateTime.to_unix(:second)
        |> Kernel.+(-1)
        |> DateTime.from_unix!(:second)
      else
        nil
      end

    token =
      %BankToken{
        token_id: token_id,
        atm_id: acc.atm_id,
        account_number: acc.account_number,
        connection_id: connection_id,
        expiration_date: expiration_date
      }

    {token, %{acc: acc}}
  end

  @doc """
  Related data:
    acc1 :: BankAccount.t, \
    acc2 :: BankAccount.t, \
    Account.t, \
    Tunnel.t, \
    Server.t
  """
  def wire_transfer_flow do
    amount = 1
    {acc1, _} = account([balance: amount, atm_seq: 1])
    {acc2, _} = account([atm_seq: 2])
    {player, %{server: gateway}} = AccountSetup.account([with_server: true])

    {tunnel, _} =
      NetworkSetup.tunnel(
        gateway_id: gateway.server_id, target_id: acc1.atm_id
      )

    {:ok, process} =
      BankTransferFlow.start(acc1, acc2, amount, player, gateway, tunnel, nil)

    related = %{
      acc1: acc1,
      acc2: acc2,
      player: player,
      tunnel: tunnel,
      gateway: gateway
    }

    {process, related}
  end

  @doc """
  Related data: BankAccount.t, Server.t, Entity.t
  """
  def login_flow do
    {acc, _} = account()
    {server, %{entity: entity}} = ServerSetup.server()

    # Login with the right password
    {:ok, connection} =
      BankAccountFlow.login_password(
        acc.atm_id, acc.account_number, server.server_id, nil, acc.password
      )

    {connection, %{acc: acc, server: server, entity: entity}}
  end
end
