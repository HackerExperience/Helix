defmodule HELM.Software.Repo.Migrations.FixCompositePks do
  use Ecto.Migration

  def change do
    drop unique_index(:storage_drives, [:storage_id])

    alter table(:storage_drives, primary_key: false) do
      remove :drive_id
      remove :storage_id

      add :drive_id, :integer, primary_key: true
      add :storage_id, references(:storages, column: :storage_id, type: :string), primary_key: true
    end
  end
end
