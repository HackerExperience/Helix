defmodule Helix.Software.Repo.Migrations.CreateFileTypeTable do
  use Ecto.Migration

  def change do
    create table(:file_types, primary_key: false) do
      add :file_type, :string, primary_key: true
      add :extension, :string

      timestamps()
    end
  end
end
