defmodule Helix.Universe.Bank.Action.Flow.BankTransfer do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Account.Model.Account
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Action.Tunnel, as: TunnelAction
  alias Helix.Network.Query.Network, as: NetworkQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Process.Action.Process, as: ProcessAction
  alias Helix.Universe.Bank.Action.Bank, as: BankAction
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Universe.Bank.Model.BankTransfer
  alias Helix.Universe.Bank.Model.BankTransfer.ProcessType

  @spec start(
    from_account :: BankAccount.t,
    to_account :: BankAccount.t,
    amount :: pos_integer,
    started_by :: Account.idt,
    bounces :: [Server.id])
  ::
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
  def start(from_account, to_account, amount, started_by, bounces \\ []) do

    # TODO: *do* need the gateway_id because of List.first()
    gateway_server =
      started_by
      |> EntityQuery.get_entity_id()
      |> EntityQuery.fetch()
      |> EntityQuery.get_servers()
      |> List.first()
      |> ServerQuery.fetch()

    server_atm_to =
      to_account.atm_id
      |> ServerQuery.fetch()

    bounces =
      if from_account.atm_id == to_account.atm_id do
        bounces
      else
        server_atm_from =
          from_account.atm_id
          |> ServerQuery.fetch()

        bounces ++ [server_atm_from.server_id]
      end

    start_transfer = fn ->
      BankAction.start_transfer(
        from_account,
        to_account,
        amount,
        started_by.account_id)
    end

    start_connection = fn ->
      TunnelAction.connect(
        NetworkQuery.internet(),
        gateway_server.server_id,
        server_atm_to.server_id,
        bounces,
        :wire_transfer
      )
    end

    create_params = fn(transfer, connection) ->
      %{
        gateway_id: gateway_server.server_id,
        target_server_id: gateway_server.server_id,
        network_id: NetworkQuery.internet().network_id,
        objective: %{cpu: amount},
        connection_id: connection.connection_id,
        process_data: %ProcessType{
          transfer_id: transfer.transfer_id,
          amount: amount
        },
        process_type: "wire_transfer"
      }
    end

    flowing do
      with \
        {:ok, transfer} <- start_transfer.(),
        on_fail(fn -> BankAction.abort_transfer(transfer) end),

        {:ok, connection, events} <- start_connection.(),
        on_fail(fn -> TunnelAction.close_connection(connection) end),
        on_success(fn -> Event.emit(events) end),

        params = create_params.(transfer, connection),
        {:ok, process, events} <- ProcessAction.create(params),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, process}
      end
    end
  end
end
