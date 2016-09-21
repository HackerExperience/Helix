defmodule HELM.Entity.Controller do
  import Ecto.Query

  alias HELM.Entity.{Repo, Schema}

  def create(entity) do
    changeset = Schema.changeset(%Schema{}, entity)
    case Repo.insert(changeset) do
       {:ok, _} ->
         Broker.cast("event:entity:created", changeset.changes.entity_id)
         :ok
       {:error, _} -> changeset
    end
  end
end
