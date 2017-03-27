defmodule Helix.Software.Repo.Migrations.RenameFileTypeToSoftwareType do
  use Ecto.Migration

  def change do
    drop unique_index(:files, [:storage_id, :file_path, :name, :file_type], name: :unique_file_path_index)
    drop unique_index(:module_roles, [:file_type, :module_role], name: :file_type_module_role_unique_constraint)

    alter table(:files) do
      remove :file_type
    end

    alter table(:module_roles) do
      remove :file_type
    end

    drop table(:file_types)

    create table(:software_types, primary_key: false) do
      add :software_type, :string, primary_key: true
      add :extension, :string, null: false
    end

    alter table(:files) do
      add :software_type, references(:software_types, column: :software_type, type: :string), null: false
    end

    alter table(:module_roles) do
      add :software_type, references(:software_types, column: :software_type, type: :string), null: false
    end

    create unique_index(:files, [:storage_id, :file_path, :name, :software_type])
    create unique_index(:module_roles, [:module_role, :software_type])
  end
end
