defmodule HELM.Software.Module.Role.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Software.File.Type.Schema, as: SoftFileTypeSchema
  alias Ecto.Changeset

  @primary_key false
  @creation_fields ~w/file_type module_role/a

  schema "module_roles" do
    belongs_to :file_types, SoftFileTypeSchema,
      foreign_key: :file_type,
      references: :file_type,
      type: :string,
      primary_key: true

    field :module_role, :string, primary_key: true

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
  end
end
