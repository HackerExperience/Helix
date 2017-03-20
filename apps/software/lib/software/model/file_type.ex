defmodule Helix.Software.Model.FileType do

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
    file_type: String.t,
    extension: String.t
  }

  @creation_fields ~w/file_type extension/a

  @primary_key false
  schema "file_types" do
    field :file_type, :string,
      primary_key: true

    field :extension, :string
  end

  @spec create_changeset(%{file_type: String.t, extension: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@creation_fields)
    |> unique_constraint(:file_type)
  end
end