defmodule HELM.Software.Repo.Migrations.CreateModulesTable do
  use Ecto.Migration

  def change do
    create table(:modules, primary_key: false) do
      add :file_id, references(:files, column: :file_id, type: :string), primary_key: true
      add :module_role, references(:module_roles, column: :module_role, type: :string), primary_key: true
      add :module_version, :integer

      timestamps
    end
  end
end
