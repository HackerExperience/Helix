defmodule Helix.Test.Entity.Helper do

  import Ecto.Query

  alias Helix.Entity.Model.EntityServer
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
end
