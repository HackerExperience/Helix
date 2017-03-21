defmodule Helix.Software.Repo.Migrations.RenameFileTypeToSoftwareType do
  use Ecto.Migration

  def change do
    drop unique_index(:files, [:storage_id, :file_path, :name, :file_type], name: :unique_file_path_index)

    alter table(:files) do
      remove :file_type
    end

    alter table(:module_roles) do
      remove :file_type
    end

    create table(:software_types, primary_key: false) do
      add :software_type, :string, primary_key: true
      add :extension, :string
    end

    alter table(:files) do
      add :software_type,
        references(:software_types, column: :software_type, type: :string)
    end

    alter table(:module_roles) do
      add :software_type,
        references(:software_types, column: :software_type, type: :string)
    end

    create unique_index(:files, [:storage_id, :file_path, :name, :software_type], name: :unique_file_path_index)
  end
end