defmodule HELM.Hardware.Model.Motherboards do

  use Ecto.Schema

  alias HELL.PK
  alias HELM.Hardware.Model.MotherboardSlot, as: MdlMoboSlot, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    motherboard_id: PK.t,
    slots: [MdlMoboSlot.t],
    inserted_at: Ecto.DateTime.t,
    updated_at: Ecto.DateTime.t
  }

  @primary_key {:motherboard_id, EctoNetwork.INET, autogenerate: false}
  schema "motherboards" do
    has_many :slots, MdlMoboSlot,
      foreign_key: :motherboard_id,
      references: :motherboard_id

    timestamps
  end

  @spec create_changeset() :: Ecto.Changeset.t
  def create_changeset do
    %__MODULE__{}
    |> cast(%{}, [])
    |> put_primary_key()
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    ip = PK.generate([0x0003, 0x0003, 0x0000])

    changeset
    |> cast(%{motherboard_id: ip}, [:motherboard_id])
  end
end