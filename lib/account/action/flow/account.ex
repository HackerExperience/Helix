defmodule Helix.Account.Action.Flow.Account do

  import HELF.Flow

  alias Helix.Entity.Action.Entity, as: EntityAction
  alias Helix.Entity.Model.Entity
  alias Helix.Server.Action.Flow.Server, as: ServerFlow
  alias Helix.Server.Model.Server
  alias Helix.Account.Model.Account
  alias Helix.Account.Query.Account, as: AccountQuery

  @spec setup_account(Account.id | Account.t) ::
    {:ok, %{entity: Entity.t, server: Server.t}}
    | :error
  # TODO: improve documentation
  @doc """
  Setups the input account
  """
  def setup_account(account = %Account{}) do
    flowing do
      with \
        {:ok, entity} <- EntityAction.create_from_specialization(account),
        on_fail(fn -> EntityAction.delete(entity) end),

        {:ok, server} <- ServerFlow.setup_server(entity)
      do
        {:ok, %{entity: entity, server: server}}
      else
        _ ->
          # TODO: Improve returned error
          :error
      end
    end
  end

  def setup_account(account_id) when is_binary(account_id) do
    account_id
    |> AccountQuery.fetch()
    |> setup_account()
  end
end
