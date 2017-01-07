defmodule Helix.Software.Repo.Migrations.CreateFileTable do
  use Ecto.Migration

  def change do
    create table(:files, primary_key: false) do
      add :file_id, :string, primary_key: true
      add :name, :string
      add :file_path, :string
      add :file_size, :integer
      add :file_type, references(:file_types, column: :file_type, type: :string)
      add :storage_id, references(:storages, column: :storage_id, type: :string)

      timestamps()
    end
  end
end
