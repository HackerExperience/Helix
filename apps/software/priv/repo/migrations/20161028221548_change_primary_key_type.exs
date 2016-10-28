defmodule HELM.Software.Repo.Migrations.ChangePrimaryKeyType do
  use Ecto.Migration

  def change do
    alter table(:modules) do
      remove :file_id
    end

    alter table(:files) do
      remove :file_id
      remove :storage_id
      add :file_id, :binary_id, primary_key: true
    end

    alter table(:storage_drives) do
      remove :storage_id
    end

    alter table(:storages) do
      remove :storage_id
      add :storage_id, :binary_id, primary_key: true
    end

    alter table(:storage_drives) do
      add :storage_id, references(:storages, column: :storage_id, type: :binary_id), primary_key: true
    end

    alter table(:files) do
      add :storage_id, references(:storages, column: :storage_id, type: :binary_id)
    end

    alter table(:modules) do
      add :file_id, references(:files, column: :file_id, type: :binary_id), primary_key: true
    end
  end
end