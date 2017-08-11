defmodule Helix.Universe.Bank.Model.Bank do

  use Ecto.Schema

  alias Helix.Account.Model.Account
  alias Helix.Universe.Bank.Model.ATM
  alias Helix.Universe.NPC.Model.NPC

  import Ecto.Changeset

  @type t :: %__MODULE__{
    bank_id: NPC.id,
    name: String.t
  }

  @type creation_params :: %{
    :bank_id => NPC.id,
    :name => String.t
  }

  @creation_fields ~w/bank_id name/a

  @primary_key false
  schema "banks" do
    field :bank_id, NPC.ID,
      primary_key: true
    field :name, :string

    belongs_to :npc, NPC,
      references: :npc_id,
      foreign_key: :bank_id,
      primary_key: false,
      define_field: false

    has_many :atm, ATM,
      foreign_key: :bank_id,
      references: :bank_id
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
