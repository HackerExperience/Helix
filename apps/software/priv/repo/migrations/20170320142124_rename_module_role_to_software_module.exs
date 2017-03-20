defmodule Helix.Software.Repo.Migrations.RenameModuleRoleToSoftwareModule do
  use Ecto.Migration

  def change do
    drop table(:file_modules)
    drop table(:module_roles)

    create table(:software_modules, primary_key: false) do
      add :software_module_id, :inet, primary_key: true
      add :software_module, :string
      add :file_type,
        references(:file_types,
          column: :file_type,
          type: :string),
        null: false
    end

    create unique_index(:software_modules, [:file_type, :software_module],
      name: :file_type_software_module_unique_constraint)

    create table(:file_modules, primary_key: false) do
      add :file_id,
        references(:files,
          column: :file_id,
          type: :inet,
          on_delete: :delete_all),
        primary_key: true

      add :software_module_id,
        references(:software_modules,
          column: :software_module_id,
          type: :inet,
          on_delete: :nothing,
          on_update: :nothing),
        primary_key: true

      add :module_version, :integer
    end

    create constraint(:file_modules, :module_version_must_be_positive, check: "module_version > 0")
  end
end
