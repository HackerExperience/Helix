defmodule HELM.Software.Module.Role.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Software.File.Type.Schema, as: FileTypeSchema
  alias HELM.Software.Module.Schema, as: ModuleSchema
  alias Ecto.Changeset

  @primary_key {:module_role, :string, autogenerate: false}
  @creation_fields ~w/file_type module_role/a

  schema "module_roles" do
    belongs_to :file_type_entity, FileTypeSchema,
      foreign_key: :file_type,
      references: :file_type,
      type: :string

    has_many :modules, ModuleSchema,
      foreign_key: :module_role,
      references: :module_role

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
  end
end
