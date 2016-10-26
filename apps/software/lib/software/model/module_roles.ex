defmodule HELM.Software.Model.ModuleRoles do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Software.Model.FileTypes, as: MdlFileTypes
  alias HELM.Software.Model.Modules, as: MdlModules
  alias Ecto.Changeset

  @primary_key {:module_role, :string, autogenerate: false}
  @creation_fields ~w/file_type module_role/a

  schema "module_roles" do
    belongs_to :file_type_entity, MdlFileTypes,
      foreign_key: :file_type,
      references: :file_type,
      type: :string

    has_many :modules, MdlModules,
      foreign_key: :module_role,
      references: :module_role

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
  end
end
