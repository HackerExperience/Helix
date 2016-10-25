defmodule HELM.Entity.Type.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity.Repo
  alias HELM.Entity.Type.Schema, as: EntityTypeSchema

  def create(type_name) do
    %{entity_type: type_name}
    |> EntityTypeSchema.create_changeset()
    |> Repo.insert()
  end

  def find(type_name) do
    case Repo.get_by(EntityTypeSchema, entity_type: type_name) do
      nil -> {:error, :notfound}
      entity_type -> {:ok, entity_type}
    end
  end

  def delete(type_name) do
    with {:ok, entity_type} <- find(type_name),
         {:ok, _} <- Repo.delete(entity_type) do
      :ok
    else
      {:error, :notfound} -> :ok
    end
  end
end
