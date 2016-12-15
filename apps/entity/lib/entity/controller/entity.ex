defmodule HELM.Entity.Controller.Entity do

  alias HELM.Entity.Model.Entity, as: MdlEntity
  alias Helix.Entity.Model.EntityAccount
  alias HELM.Entity.Repo
  import Ecto.Query, only: [where: 3]

  @spec create(MdlEntity.creation_params) :: {:ok, MdlEntity.t} | no_return
  def create(params) do
    Repo.transaction(fn ->
      params
      |> MdlEntity.create_changeset()
      |> Repo.insert!()
      |> create_specialization()
    end)
  end

  @spec find(MdlEntity.id) :: {:ok, MdlEntity.t} | {:error, :notfound}
  def find(entity_id) do
    case Repo.get_by(MdlEntity, entity_id: entity_id) do
      nil ->
        {:error, :notfound}
      entity ->
        {:ok, entity}
    end
  end

  @spec delete(MdlEntity.id) :: no_return
  def delete(entity_id) do
    MdlEntity
    |> where([s], s.entity_id == ^entity_id)
    |> Repo.delete_all()

    :ok
  end

  @spec create_specialization(MdlEntity.t) :: MdlEntity.t
  defp create_specialization(entity = %{entity_type: "account"}) do
    %{entity_id: entity.entity_id}
    |> EntityAccount.create_changeset()
    |> Repo.insert!()

    entity
  end
  defp create_specialization(entity = %{entity_type: "npc"}) do
    # FIXME
    entity
  end
  defp create_specialization(entity = %{entity_type: "clan"}) do
    # FIXME
    entity
  end
end