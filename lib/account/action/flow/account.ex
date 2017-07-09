defmodule Helix.Account.Action.Flow.Account do

  import HELF.Flow

  alias Helix.Account.Model.Account
  alias Helix.Account.Query.Account, as: AccountQuery
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Entity.Action.Entity, as: EntityAction

  @spec setup_account(HELL.PK.t | Account.t) ::
    {:ok, %{entity: struct, server: struct}}
    | :error
  @doc """
  Setups the input account
  """
  def setup_account(account_id) when is_binary(account_id),
    do: setup_account(AccountQuery.fetch(account_id))
  def setup_account(account) do
    flowing do
      with \
        {:ok, entity} <- EntityAction.create_from_specialization(account),
        on_fail(fn -> EntityAction.delete(entity) end),

        {:ok, server} <- ServerFlow.setup_server(entity)
      do
        {:ok, %{entity: entity, server: server}}
      else
        _ ->
          :error
      end
    end
  end

end
