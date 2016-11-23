defmodule HELM.Software.Model.ModuleRole do

  use Ecto.Schema

  alias HELM.Software.Model.FileType, as: MdlFileType, warn: false
  alias HELM.Software.Model.Module, as: MdlModule, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    module_role: String.t,
    type: MdlFileType.t,
    modules: [MdlModule.t]
  }

  @creation_fields ~w/file_type module_role/a

  @primary_key false
  schema "module_roles" do
    field :module_role, :string,
      primary_key: true

    # FIXME: this name must change soon
    belongs_to :type, MdlFileType,
      foreign_key: :file_type,
      references: :file_type,
      type: :string
    has_many :modules, MdlModule,
      foreign_key: :module_role,
      references: :module_role
  end

  @spec create_changeset(%{file_type: String.t, module_role: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required([:module_role, :file_type])
    |> unique_constraint(:module_role)
  end
end