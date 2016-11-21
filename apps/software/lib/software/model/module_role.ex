defmodule HELM.Software.Model.ModuleRole do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELM.Software.Model.FileType, as: MdlFileType, warn: false
  alias HELM.Software.Model.Module, as: MdlModule, warn: false

  @primary_key {:module_role, :string, autogenerate: false}
  @creation_fields ~w/file_type module_role/a

  schema "module_roles" do
    # FIXME: this name must change soon
    belongs_to :type, MdlFileType,
      foreign_key: :file_type,
      references: :file_type,
      type: :string

    has_many :modules, MdlModule,
      foreign_key: :module_role,
      references: :module_role
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:module_role)
  end
end