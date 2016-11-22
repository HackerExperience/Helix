defmodule HELM.Software.Model.FileType do

  use Ecto.Schema
  import Ecto.Changeset

  alias HELM.Software.Model.File, as: MdlFile, warn: false
  alias HELM.Software.Model.ModuleRole, as: MdlModuleRole, warn: false

  @type t :: %__MODULE__{
    file_type: String.t,
    extension: String.t,
    files: [MdlFile.t],
    module_roles: [MdlModuleRole.t]
  }

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
  end

  @spec create_changeset(%{file_type: String.t, extension: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:file_type)
    |> unique_constraint(:file_type)
  end
end