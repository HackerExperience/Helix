defmodule Helix.Network.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    create table(:networks, primary_key: false) do
      add :network_id, :inet, primary_key: true
      add :name, :string
    end

    # NOTE: `tunnels` was rewritten at the AddBounce migration
    create table(:tunnels, primary_key: false) do
      add :tunnel_id, :inet, primary_key: true
      add :network_id,
        references(
          :networks, column: :network_id, type: :inet, on_delete: :delete_all
        ),
        null: false
      add :gateway_id, :inet, null: false
      add :destination_id, :inet, null: false
      add :hash, :string, null: false  # Removed
      # add :bounce_id, :inet
    end

    # Index removed
    create unique_index(
      :tunnels,
      [:network_id, :gateway_id, :destination_id, :hash]
    )

    # Below indexes are specially useful when figuring out which tunnels or
    # connections are incoming/outgoing to the specific server.
    create index(:tunnels, [:gateway_id])  # Removed (superseded by other index)
    create index(:tunnels, [:destination_id])

    create table(:links, primary_key: false) do
      add :tunnel_id,
        references(
          :tunnels, column: :tunnel_id, type: :inet, on_delete: :delete_all
        ),
        primary_key: true
      add :source_id, :inet, primary_key: :true
      add :destination_id, :inet, null: false  # Renamed to `target_id`

      add :sequence, :integer, null: false
    end
    # create index(:links, [:source_id, :target_id])

    create table(:connections, primary_key: false) do
      add :connection_id, :inet, primary_key: :true
      add :tunnel_id,
        references(
          :tunnels, column: :tunnel_id, type: :inet, on_delete: :delete_all
        ),
        null: false

      add :connection_type, :string, null: false
      add :meta, :map
    end

    create index(:connections, [:tunnel_id])
  end
end
