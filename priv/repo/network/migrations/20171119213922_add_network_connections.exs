defmodule Helix.Network.Repo.Migrations.AddNetworkConnections do
  use Ecto.Migration

  def change do
    create table(:network_connections, primary_key: false) do
      add :network_id,
        references(
          :networks,
          column: :network_id,
          type: :inet,
          on_delete: :delete_all),
        primary_key: true

      add :ip, :inet, primary_key: true

      add :entity_id, :inet, null: false
      add :nic_id, :inet
    end

    # Secondary index used to figure out which Entity the NC belongs to
    create index(:network_connections, [:entity_id])

    # Secondary index used to figure out which NIP belongs to which NIC
    # It's a partial index because NetworkConnections may have no NIC assigned
    # to it, meaning the NetworkConnection is idle / not in use.
    create unique_index(
      :network_connections, [:nic_id], where: "nic_id IS NOT NULL"
    )
  end
end
