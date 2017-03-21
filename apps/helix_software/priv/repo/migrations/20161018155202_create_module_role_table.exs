defmodule Helix.Software.Repo.Migrations.CreateModuleRoleTable do
  use Ecto.Migration

  def change do
    create table(:module_roles, primary_key: false) do
      add :file_type, references(:file_types, column: :file_type, type: :string), primary_key: true
      add :module_role, :string, primary_key: true

      timestamps()
    end
  end
end
