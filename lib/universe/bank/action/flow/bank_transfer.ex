# credo:disable-for-this-file Credo.Check.Refactor.FunctionArity
defmodule Helix.Universe.Bank.Action.Flow.BankTransfer do

  alias Helix.Event
  alias Helix.Account.Model.Account
  alias Helix.Network.Model.Tunnel
  alias Helix.Process.Model.Process
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Bank.Process.Bank.Transfer, as: BankTransferProcess

  @spec start(
    from_account :: BankAccount.t,
    to_account :: BankAccount.t,
    amount :: BankTransfer.amount,
    started_by :: Account.t,
    gateway :: Server.t,
    Tunnel.t,
    Event.relay)
  ::
    {:ok, Process.t}
    | {:error, {:funds, :insufficient}}
    | {:error, {:account, :notfound}}
    | {:error, :internal}
  @doc """
  Starts a bank transfer.

  Other than creating the bank transfer, which is delegated to
  `BankAction.start_transfer()`, it also is responsible for creating the
  transfer process to be managed by TOP.
  """
  def start(
    from_account, to_account, amount, started_by, gateway, tunnel, relay)
  do
    start_transfer = fn ->
      BankAction.start_transfer(
        from_account, to_account, amount, started_by.account_id
      )
    end

    # TODO #379
    # bounces =
    #   if from_account.atm_id == to_account.atm_id do
    #     []
    #   else
    #     server_atm_from =
    #       from_account.atm_id
    #       |> ServerQuery.fetch()

    #     [server_atm_from.server_id]
    #   end

    with \
      target_atm = %Server{} <- ServerQuery.fetch(to_account.atm_id),
      {:ok, transfer} <- start_transfer.()
    do
      params = %{
        transfer: transfer
      }

      meta = %{
        network_id: tunnel.network_id,
        bounce_id: tunnel.bounce_id
      }

      BankTransferProcess.execute(gateway, target_atm, params, meta, relay)

    else
      error = {:error, {_, _}} ->
        error

      _ ->
        {:error, :internal}
    end
  end
end
