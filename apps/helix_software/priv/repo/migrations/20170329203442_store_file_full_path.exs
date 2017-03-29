defmodule Helix.Software.Repo.Migrations.StoreFileFullPath do
  use Ecto.Migration

  def change do
    drop unique_index(:files, [:storage_id, :file_path, :name, :software_type])

    alter table(:files) do
      remove :file_path
      add :path, :string, null: false
      add :full_path, :string, null: false
    end

    create unique_index(:files, [:storage_id, :full_path])
  end
end
