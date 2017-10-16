defmodule Helix.Software.Repo.Migrations.AddPublicFTP do
  use Ecto.Migration

  def change do

    create table(:pftps, primary_key: false) do
      add :server_id, :inet, primary_key: true

      add :is_active, :boolean, null: false
    end

    create table(:pftp_files, primary_key: false) do
      add :server_id, :inet, primary_key: true

      add :file_id,
        references(
          :files,
          column: :file_id,
          type: :inet,
          on_delete: :nilify_all
        ),
        primary_key: true

      add :inserted_at, :utc_datetime, default: fragment("now()")
    end

    # Reverse index used to identify whether a file is being used on public FTP
    create unique_index(:pftp_files, [:file_id])
  end
end
