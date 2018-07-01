defmodule Helix.Test.Entity.Helper do

  import Ecto.Query

  alias Helix.Account.Model.Account
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.EntityServer
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Entity.Repo, as: EntityRepo

  @doc """
  Naively changes the owner of the server to the given entity id.
  """
  def change_server_owner(server_id, new_entity_id) do
    EntityServer
    |> where([es], es.server_id == ^server_id)
    |> EntityRepo.one()
    |> Ecto.Changeset.change()
    |> Ecto.Changeset.put_change(:entity_id, new_entity_id)
    |> EntityRepo.update!()
  end

  def fetch_entity_from_account(account = %Account{}),
    do: fetch_entity_from_account(account.account_id)
  def fetch_entity_from_account(account_id = %Account.ID{}) do
    account_id
    |> EntityQuery.get_entity_id()
    |> EntityQuery.fetch()
  end

  def id,
    do: Entity.ID.generate({:entity, :account})
end
