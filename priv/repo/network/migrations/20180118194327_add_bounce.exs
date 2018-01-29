defmodule Helix.Network.Repo.Migrations.AddBounce do
  use Ecto.Migration

  def change do
    create table(:bounces, primary_key: false) do
      add :bounce_id, :inet, primary_key: true
      add :entity_id, :inet, null: false
      add :name, :string, size: 128, null: false
    end
    create index(:bounces, [:entity_id])

    create table(:bounce_entries, primary_key: false) do
      add :bounce_id,
        references(
          :bounces, column: :bounce_id, type: :inet, on_delete: :delete_all
        ),
        primary_key: true

      add :server_id, :inet, primary_key: true
      add :network_id,
        references(:networks, column: :network_id, type: :inet),
        primary_key: true
      add :ip, :inet, null: false
    end
    create index(:bounce_entries, [:server_id])
    create index(:bounce_entries, [:network_id, :ip])

    create table(:sorted_bounces, primary_key: false) do
      add :bounce_id,
        references(
          :bounces, column: :bounce_id, type: :inet, on_delete: :delete_all
        ),
        primary_key: true

      add :sorted_nips, {:array, :map}, null: false
    end

    drop index(:tunnels, [:gateway_id])
    drop index(:tunnels, [:destination_id])
    drop index(:tunnels, [:network_id, :gateway_id, :destination_id, :hash])

    alter table(:tunnels, primary_key: false) do
      add :bounce_id, references(:bounces, column: :bounce_id, type: :inet)
      remove :hash
    end

    rename table(:tunnels, primary_key: false), :destination_id, to: :target_id

    create index(:tunnels, [:target_id])
    create index(:tunnels, [:bounce_id], where: "bounce_id IS NOT NULL")

    create unique_index(
      :tunnels, [:gateway_id, :target_id, :network_id, :bounce_id]
    )

    rename table(:links, primary_key: false), :destination_id, to: :target_id
    create index(:links, [:source_id, :target_id])
  end
end
