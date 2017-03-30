defmodule Helix.Software.Repo.Migrations.AddCryptoKeySoftware do
  use Ecto.Migration

  def change do
    create table(:crypto_keys, primary_key: false) do
      add :file_id, references(:files, column: :file_id, type: :inet, on_delete: :delete_all), primary_key: true

      # REVIEW: Maybe leave the `on_delete` as nothing and centralize file
      #   delete to ensure that any table that has a soft link (like this one)
      #   is nilified and events are emited if any
      add :target_file_id, references(:files, column: :file_id, type: :inet, on_delete: :nilify_all)

      add :target_server_id, :inet, null: false
    end

    alter table(:files) do
      add :crypto_version, :integer
    end

    create index(:crypto_keys, [:target_file_id])
    create index(:crypto_keys, [:target_server_id])
  end
end
