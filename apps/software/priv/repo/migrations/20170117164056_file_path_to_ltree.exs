defmodule Helix.Software.Repo.Migrations.FilePathToLtree do

  use Ecto.Migration

  def up do
    execute "CREATE EXTENSION IF NOT EXISTS ltree"

    alter table(:files) do
      remove :file_path
      add :file_path, :ltree
    end

    create unique_index(:files, [:storage_id, :file_path, :name, :file_type], name: :unique_file_path_index)
  end

  def down do
    execute "DROP EXTENSION IF EXISTS ltree"

    alter table(:files) do
      remove :file_path
      add :file_path, :string
    end

    drop unique_index(:files, [:storage_id, :file_path, :name, :file_type], name: :unique_file_path_index)
  end
end