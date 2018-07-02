defmodule Helix.Test.Account.Helper do

  import Ecto.Query, only: [from: 1]

  alias Helix.Entity.Model.Entity
  alias Helix.Account.Model.Account
  alias Helix.Account.Query.Account, as: AccountQuery
  alias Helix.Account.Repo, as: AccountRepo

  @doc """
  Fetches all accounts
  """
  def get_all,
    do: AccountRepo.all(from a in Account)

  def fetch_account_from_entity(entity = %Entity{}),
    do: fetch_account_from_entity(entity.entity_id)
  def fetch_account_from_entity(entity_id = %Entity.ID{}) do
    entity_id
    |> to_string()
    |> Account.ID.cast!()
    |> AccountQuery.fetch()
  end

  def id,
    do: Account.ID.generate()

  @doc """
  Returns the Account.id that corresponds to the given Entity.id
  """
  def cast_from_entity(entity_id),
    do: Account.cast_from_entity(entity_id)
end
