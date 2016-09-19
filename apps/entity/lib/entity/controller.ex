defmodule HELM.Entity.Controller do
  import Ecto.Query

  alias HELM.Entity.{Repo, Model}

  def create(entity) do
    changeset = Model.changeset(%Model{}, entity)
    case Repo.insert(changeset) do
       {:ok, res} -> :ok
       {:error, _} -> changeset
    end
  end
end
