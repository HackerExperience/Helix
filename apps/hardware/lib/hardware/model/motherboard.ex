defmodule HELM.Hardware.Model.Motherboards do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.UUID, as: HUUID
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot

  @primary_key {:motherboard_id, :binary_id, autogenerate: false}

  schema "motherboards" do
    has_many :slots, MdlMoboSlot,
      foreign_key: :motherboard_id,
      references: :motherboard_id

    timestamps
  end

  def create_changeset do
    %__MODULE__{}
    |> cast(%{}, [])
    |> put_uid
  end

  defp put_uid(changeset) do
    if changeset.valid?,
      do: put_change(changeset, :motherboard_id, uuid()),
      else: changeset
  end

  defp uuid,
    do: HUUID.create!("02", meta1: "3")
end