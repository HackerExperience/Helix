defmodule HELM.Entity.Controller.EntityTypes do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity.Model.Repo
  alias HELM.Entity.Model.EntityTypes, as: MdlEntityTypes

  def create(type_name) do
    %{entity_type: type_name}
    |> MdlEntityTypes.create_changeset()
    |> Repo.insert()
  end

  def find(type_name) do
    case Repo.get_by(MdlEntityTypes, entity_type: type_name) do
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