defmodule HELM.Software.File.Type.Schema do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Changeset

  alias HELM.Software.File.Schema, as: FileSchema
  alias HELM.Software.Module.Role.Schema, as: ModuleRoleSchema

  @primary_key {:file_type, :string, autogenerate: false}
  @creation_fields ~w/file_type extension/a

  schema "file_types" do
    field :extension, :string

    has_many :files, FileSchema,
      foreign_key: :file_type,
      references: :file_type

    has_many :module_roles, ModuleRoleSchema,
      foreign_key: :file_type,
      references: :file_type

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
  end
end
