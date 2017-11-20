defmodule Helix.Network.Repo.Migrations.AddNetworkConnections do
  use Ecto.Migration

  def change do
    create table(:network_connections, primary_key: false) do
      add :network_id, :inet, primary_key: true

      add :ip, :inet, primary_key: true

      add :nic_id, :inet
    end

    # Secondary index used to figure out which NIP belongs to which NIC
    # Notice a NIP may be unassigned to a NIC, in which case the connection is
    # not valid. This specific scenario should be temporary
    create unique_index(
      :network_connections, [:nic_id], where: "nic_id IS NOT NULL"
    )
  end
end
