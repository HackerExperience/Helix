defmodule HELM.Software.Model.Modules do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Software.Model.ModuleRoles, as: MdlModuleRoles
  alias HELM.Software.Model.Files, as: MdlFiles
  alias Ecto.Changeset

  @primary_key false
  @creation_fields ~w/file_id module_role module_version/a

  schema "modules" do
    belongs_to :file_entity, MdlFiles,
      foreign_key: :file_id,
      references: :file_id,
      type: :string,
      primary_key: true

    belongs_to :module_role_entity, MdlModuleRoles,
      foreign_key: :module_role,
      references: :module_role,
      type: :string,
      primary_key: true

    field :module_version, :integer

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_number(:module_version, greater_than: 0)
  end
end
