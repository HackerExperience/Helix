defmodule Helix.Server.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    create table(:server_types, primary_key: false) do
      add :server_type, :string, primary_key: true
    end

    # M
    create table(:servers, primary_key: false) do
      add :server_type,
        references(
          :server_types,
          column: :server_type,
          type: :string)
      add :server_id, :inet, primary_key: true

      add :password, :string, null: false

      # hostname (AddHostnameMigration)

      # Now `motherboard_id` is a FK to the mobo component (See HardwareRewrite)
      add :motherboard_id, :inet

      # timestamps were removed (See HardwareRewriteMigration)
      timestamps()
    end

    create unique_index(:servers, [:motherboard_id])
  end
end
