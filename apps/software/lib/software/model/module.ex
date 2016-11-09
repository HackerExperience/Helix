defmodule HELM.Software.Model.Module do
  use Ecto.Schema
  import Ecto.Changeset

  alias HELM.Software.Model.ModuleRole, as: MdlModuleRole, warn: false
  alias HELM.Software.Model.File, as: MdlFile, warn: false

  @primary_key false
  @creation_fields ~w/file_id module_role module_version/a

  schema "modules" do
    field :module_version, :integer

    belongs_to :file, MdlFile,
      foreign_key: :file_id,
      references: :file_id,
      type: EctoNetwork.INET,
      primary_key: true

    belongs_to :role, MdlModuleRole,
      foreign_key: :module_role,
      references: :module_role,
      type: :string,
      primary_key: true

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_number(:module_version, greater_than: 0)
  end
end