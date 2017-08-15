defmodule Helix.Universe.Bank.Model.ATM do

  use Ecto.Schema

  import Ecto.Changeset

  alias Helix.Server.Model.Server
  alias Helix.Universe.NPC.Model.NPC
  alias Helix.Universe.Bank.Model.Bank

  @type idtb :: Server.idtb | t
  @type idt :: Server.idt | t
  @type id :: Server.id
  @type t :: %__MODULE__{
    atm_id: id,
    bank_id: NPC.id,
    region: String.t
  }

  @type creation_params :: %{
    atm_id: idtb,
    bank_id: NPC.idtb,
    region: String.t
  }

  @creation_fields ~w/atm_id bank_id region/a

  @primary_key false
  schema "atms" do
    field :atm_id, Server.ID,
      primary_key: true
    field :bank_id, NPC.ID
    field :region, :string

    belongs_to :bank, Bank,
      references: :bank_id,
      foreign_key: :bank_id,
      define_field: false,
      primary_key: false
  end

  @spec create_changeset(creation_params) ::
    Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
  end

  defp generic_validations(changeset) do
    changeset
    |> validate_required(@creation_fields)
  end
end
