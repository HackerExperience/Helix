defmodule Helix.Network.Repo.Migrations.AddBounce do
  use Ecto.Migration

  def change do
    drop table(:links)

    create table(:bounces, primary_key: false) do
      add :bounce_id, :inet, primary_key: true
      add :entity_id, :inet, null: false
      add :name, :string, size: 128
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
  end
end
