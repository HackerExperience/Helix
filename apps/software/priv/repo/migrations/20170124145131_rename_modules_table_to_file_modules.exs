defmodule Helix.Software.Repo.Migrations.RenameModulesTableToFileModules do
  use Ecto.Migration

  def change do
    drop table(:modules)

    create table(:file_modules) do
      add :file_id, references(:files, column: :file_id, type: :inet, on_delete: :delete_all), primary_key: true
      add :module_role_id, references(:module_roles, column: :module_role_id, type: :inet, on_delete: :nothing, on_update: :nothing), primary_key: true
      add :module_version, :integer
    end
  end
end
