defmodule Helix.Universe.Bank.Action.Flow.BankTransfer do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Account.Model.Account
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Bank.Model.BankTransfer.ProcessType

  @spec start(BankAccount.t, BankAccount.t, pos_integer, Account.idt) ::
    {:ok, BankTransfer.t}
    | {:error, {:funds, :insufficient}}
    | {:error, {:account, :notfound}}
    | {:error, Ecto.Changeset.t}
  @doc """
  Starts a bank transfer.

  Other than creating the bank transfer, which is delegated to
  `BankAction.start_transfer()`, it also is responsible for creating the
  transfer process to be managed by TOP.
  """
  def start(from_account, to_account, amount, started_by) do

    # TODO: Transfer connection?
    # TODO: Also ask for gateway
    server =
      started_by
      |> EntityQuery.get_entity_id()
      |> EntityQuery.fetch()
      |> EntityQuery.get_servers()
      |> List.first()
      |> ServerQuery.fetch()

    start_transfer = fn ->
      BankAction.start_transfer(
        from_account,
        to_account,
        amount,
        started_by.account_id)
    end

    create_params = fn(transfer) ->
      %{
        gateway_id: server.server_id,
        target_server_id: server.server_id,
        network_id: NetworkQuery.internet(),
        objective: %{cpu: amount},
        process_data: %ProcessType{
          transfer_id: transfer.transfer_id,
          amount: amount
        },
        process_type: "bank_transfer"
      }
    end

    flowing do
      with \
        {:ok, transfer} <- start_transfer.(),
        on_fail(fn -> BankAction.abort_transfer(transfer) end),

        params = create_params.(transfer),
        {:ok, process, events} <- ProcessAction.create(params),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, process}
      end
    end
  end
end
