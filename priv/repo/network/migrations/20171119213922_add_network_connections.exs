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

      add :nic_id, :inet, null: false
    end

    # Secondary index used to figure out which NIP belongs to which NIC
    create unique_index(:network_connections, [:nic_id])
  end
end
