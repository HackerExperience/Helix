defmodule Helix.Server.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    create table(:server_types, primary_key: false) do
      add :server_type,
        :string,
        primary_key: true
    end

    create table(:servers, primary_key: false) do
      add :server_type,
        references(
          :server_types,
          column: :server_type,
          type: :string)
      add :server_id,
        :inet,
        primary_key: true
      add :poi_id,
        :inet
      add :motherboard_id,
        :inet

      timestamps()
    end

    create unique_index(:servers, [:motherboard_id])
  end
end
