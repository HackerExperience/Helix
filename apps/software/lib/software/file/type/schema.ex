defmodule HELM.Software.File.Type.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset

  @primary_key {:file_type, :string, autogenerate: false}
  @creation_fields ~w/file_type extension/a
  
  schema "file_types" do
    field :extension, :string

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
  end
end
