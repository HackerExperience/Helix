defmodule Helix.Software.Repo.Migrations.FileLocationConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:files, [:storage_id, :file_path, :name, :file_type], name: :unique_file_path_index)
  end
end
