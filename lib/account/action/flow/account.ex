defmodule Helix.Account.Action.Flow.Account do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Action.Flow.Motherboard, as: MotherboardFlow
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Model.Server
  alias Helix.Account.Action.Account, as: AccountAction
  alias Helix.Account.Model.Account

  @spec setup_account(Account.t, Event.relay) ::
    {:ok, %{entity: Entity.t, server: Server.t}}
    | {:error, :internal}
  @doc """
  Setups the input account
  """
  def setup_account(account = %Account{}, relay) do
    flowing do
      with \
        {:ok, entity} <- EntityAction.create_from_specialization(account),
        on_fail(fn -> EntityAction.delete(entity) end),

        {:ok, _motherboard, mobo} <-
           MotherboardFlow.initial_hardware(entity, relay),
        {:ok, server} <- ServerFlow.setup(:desktop, entity, mobo, relay)
      do
        {:ok, %{entity: entity, server: server}}
      else
        _ ->
          :error
      end
    end
  end

  @spec create(Account.email, Account.username, Account.password) ::
    {:ok, Account.t}
    | {:error, Ecto.Changeset.t}
  def create(email, username, password) do
    flowing do
      with \
        {:ok, account, events} <-
          AccountAction.create(email, username, password),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, account}
      end
    end
  end
end
