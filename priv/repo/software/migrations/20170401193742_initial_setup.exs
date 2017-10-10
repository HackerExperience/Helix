defmodule Helix.Software.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    create table(:storages, primary_key: false) do
      add :storage_id, :inet, primary_key: true
    end

    create table(:storage_drives, primary_key: false) do
      add :storage_id,
        references(
          :storages,
          column: :storage_id,
          type: :inet,
          on_delete: :delete_all),
        primary_key: true
      add :drive_id, :inet, primary_key: true
    end
    create unique_index(:storage_drives, [:drive_id])

    create table(:software_types, primary_key: false) do
      add :software_type, :string, primary_key: true
      add :extension, :string, null: false
    end

    create table(:files, primary_key: false) do
      add :file_id, :inet, primary_key: true
      add :software_type,
        references(:software_types, column: :software_type, type: :string),
        null: false
      add :name, :string
      add :path, :string, null: false
      add :full_path, :string, null: false
      add :file_size, :integer
      add :storage_id, references(:storages, column: :storage_id, type: :inet)
      add :crypto_version, :integer

      timestamps()
    end
    create unique_index(:files, [:storage_id, :full_path])

    create table(:software_modules, primary_key: false) do
      add :module, :string, primary_key: true
      add :software_type,
        references(:software_types, column: :software_type, type: :string),
        null: false
    end

    create table(:file_modules, primary_key: false) do
      add :file_id,
        references(
          :files,
          column: :file_id,
          type: :inet,
          on_delete: :delete_all),
        primary_key: true
      add :name,
        references(:software_modules, column: :module, type: :string),
        primary_key: true
      add :version, :integer, null: false
    end

    create constraint(
      :file_modules,
      :version_must_be_positive,
      check: "version > 0")

    # File specializations
    create table(:text_files, primary_key: false) do
      add :file_id,
        references(
          :files,
          column: :file_id,
          type: :inet,
          on_delete: :delete_all),
        primary_key: true
      add :contents, :text
    end

    create constraint(
      :text_files,
      :contents_size,
      check: "char_length(contents) <= 8192")

    create table(:crypto_keys, primary_key: false) do
      add :file_id,
        references(
          :files,
          column: :file_id,
          type: :inet,
          on_delete: :delete_all),
        primary_key: true

      # REVIEW: Maybe leave the `on_delete` as nothing and centralize file
      #   delete to ensure that any table that has a soft link (like this one)
      #   is nilified and events are emited if any
      add :target_file_id,
        references(
          :files,
          column: :file_id,
          type: :inet,
          on_delete: :nilify_all)

      add :target_server_id, :inet, null: false
    end

    create index(:crypto_keys, [:target_file_id])
    create index(:crypto_keys, [:target_server_id])
  end
end
