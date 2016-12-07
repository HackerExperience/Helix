defmodule HELM.Hardware.Controller.MotherboardSlot do

  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot
  import Ecto.Query, only: [where: 3]

  @spec create(MdlMoboSlot.creation_params) :: {:ok, MdlMoboSlot.t} | {:error, Ecto.Changeset.t}
  def create(params) do
    params
    |> MdlMoboSlot.create_changeset()
    |> Repo.insert()
  end

  @spec find(HELL.PK.t) :: {:ok, MdlMoboSlot.t} | {:error, :notfound}
  def find(slot_id) do
    case Repo.get_by(MdlMoboSlot, slot_id: slot_id) do
      nil ->
        {:error, :notfound}
      res ->
        {:ok, res}
    end
  end

  @spec find_by([{:motherboard_id, HELL.PK.t}]) :: [MdlMoboSlot.t]
  def find_by(motherboard_id: motherboard_id) do
    MdlMoboSlot
    |> where([s], s.motherboard_id == ^motherboard_id)
    |> Repo.all()
  end

  @spec update(HELL.PK.t, MdlMoboSlot.update_params) :: {:ok, MdlMoboSlot.t} | {:error, :notfound | Ecto.Changeset.t}
  def update(slot_id, params) do
    with {:ok, mobo_slot} <- find(slot_id) do
      mobo_slot
      |> MdlMoboSlot.update_changeset(params)
      |> Repo.update()
    end
  end

  @spec link(slot_id :: HELL.PK.t, component :: HELL.PK.t) ::
    {:ok, MdlMoboSlot.t}
    | {:error, :linked_component | :linked_slot | :notfound | Ecto.Changeset.t}
  def link(slot_id, link_component_id) do
    with \
      :unused_component <- unused_component?(link_component_id),
      :empty_slot <- empty_slot?(slot_id)
    do
      update(slot_id, %{link_component_id: link_component_id})
    else
      {:error, msg} ->
        {:error, msg}
      msg ->
        {:error, msg}
    end
  end

  @spec unlink(HELL.PK.t) ::
    {:ok, MdlMoboSlot.t}
    | {:error, :empty_slot | :notfound | Ecto.Changeset.t}
  def unlink(slot_id) do
    case empty_slot?(slot_id) do
      :linked_slot ->
        update(slot_id, %{link_component_id: nil})
      :empty_slot ->
        {:error, :empty_slot}
      error ->
        error
    end
  end

  @spec delete_all_from_motherboard(HELL.PK.t) :: no_return
  def delete_all_from_motherboard(motherboard_id) do
    MdlMoboSlot
    |> where([s], s.motherboard_id == ^motherboard_id)
    |> Repo.delete_all()

    :ok
  end

  @spec parse_motherboard_spec(%{String.t => any}) ::
  [%{slot_internal_id: non_neg_integer, link_component_type: String.t}]
  def parse_motherboard_spec(component_spec) do
    Enum.map(component_spec.spec["slots"], fn {id, spec} ->
      %{
        slot_internal_id: id,
        link_component_type: spec["type"]}
    end)
  end

  @spec unused_component?(HELL.PK.t) :: :unused_component | :linked_component
  defp unused_component?(component_id) do
    MdlMoboSlot
    |> where([s], s.link_component_id == ^component_id)
    |> Repo.all()
    |> Enum.empty?()
    |> case do
      true ->
        :unused_component
      false ->
        :linked_component
    end
  end

  @spec empty_slot?(HELL.PK.t) :: :empty_slot | :linked_slot | {:error, :notfound}
  defp empty_slot?(slot_id) do
    case find(slot_id) do
      {:ok, slot} ->
        if slot.link_component_id == nil do
          :empty_slot
        else
          :linked_slot
        end
      error ->
        error
    end
  end
end