defmodule HELM.Software.Model.FileType do
  use Ecto.Schema
  import Ecto.Changeset
  
  alias HELM.Software.Model.File, as: MdlFile, warn: false
  alias HELM.Software.Model.ModuleRole, as: MdlModuleRole, warn: false

  @primary_key {:file_type, :string, autogenerate: false}
  @creation_fields ~w/file_type extension/a

  schema "file_types" do
    field :extension, :string

    has_many :files, MdlFile,
      foreign_key: :file_type,
      references: :file_type

    has_many :module_roles, MdlModuleRole,
      foreign_key: :file_type,
      references: :file_type

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
  end
end