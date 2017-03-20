defmodule Helix.Software.Repo.Migrations.RenameModuleRoleToSoftwareModule do
  use Ecto.Migration

  def change do
    alter table(:file_modules) do
      remove :module_role_id
    end

    drop table(:module_roles)

    create table(:software_modules, primary_key: false) do
      add :software_module, :string, primary_key: true
      add :software_type,
        references(:software_types,
          column: :software_type,
          type: :string),
        null: false
    end

    create unique_index(:software_modules, [:software_type, :software_module])

    alter table(:file_modules) do
      add :software_module,
        references(:software_modules,
          column: :software_module,
          type: :string),
        null: false
    end
  end
end
