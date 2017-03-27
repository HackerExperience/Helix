defmodule Helix.Account.Model.Setting do

  use Ecto.Schema

  import Ecto.Changeset

  @update_fields ~w/is_beta/a

  @primary_key false
  embedded_schema do
    field :is_beta, :boolean,
      default: false
  end

  @spec changeset(Setting.t, map) :: Ecto.Changeset.t
  def changeset(struct \\ %__MODULE__{}, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_required(:is_beta)
  end
end
