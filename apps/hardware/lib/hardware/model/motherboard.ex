defmodule HELM.Hardware.Model.Motherboards do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELL.IPv6
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot, warn: false

  @primary_key {:motherboard_id, EctoNetwork.INET, autogenerate: false}

  schema "motherboards" do
    has_many :slots, MdlMoboSlot,
      foreign_key: :motherboard_id,
      references: :motherboard_id

    timestamps
  end

  def create_changeset do
    %__MODULE__{}
    |> cast(%{}, [])
    |> put_primary_key()
  end

  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0003, 0x0003, 0x0000])

    changeset
    |> cast(%{motherboard_id: ip}, ~w(motherboard_id))
  end
end