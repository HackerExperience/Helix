defmodule Helix.Hardware.Repo.Migrations.AddNetworkConnection do
  use Ecto.Migration

  def change do
    create table(:network_connections, primary_key: false) do
      add :network_connection_id, :inet, primary_key: true
      add :network_id, :inet, null: false

      add :ip, :inet, null: false

      add :downlink, :integer, null: false
      add :uplink, :integer, null: false
    end

    create unique_index(:network_connections, [:network_id, :ip], name: :network_connections_network_id_ip_unique_index)
    create constraint(:network_connections, :non_neg_downlink, check: "downlink >= 0")
    create constraint(:network_connections, :non_neg_uplink, check: "uplink >= 0")

    drop table(:nic_ips)

    drop constraint(:nics, :non_neg_downlink)
    drop constraint(:nics, :non_neg_uplink)
    alter table(:nics) do
      remove :uplink
      remove :downlink

      add :network_connection_id, references(:network_connections, column: :network_connection_id, type: :inet, on_delete: :nilify_all, name: :nics_network_connection_id_fkey)
    end
  end
end