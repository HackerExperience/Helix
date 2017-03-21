defmodule Helix.Software.Repo.Migrations.FixModuleRolePK do
  use Ecto.Migration

  def change do
    alter table(:modules) do
      remove :module_role
      remove :file_id
    end

    alter table(:module_roles) do
      remove :file_type
      remove :module_role
      add :module_role_id, :inet, primary_key: true
      add :module_role, :string
      add :file_type, references(:file_types, column: :file_type, type: :string), null: false

    end

    alter table(:modules) do
      add :file_id, references(:files, column: :file_id, type: :inet), primary_key: true
      add :module_role_id, references(:module_roles, column: :module_role_id, type: :inet), primary_key: true
    end

    create unique_index(:module_roles, [:file_type, :module_role], name: :file_type_module_role_unique_constraint)
  end
end
