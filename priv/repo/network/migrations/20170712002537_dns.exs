defmodule Helix.Network.Repo.Migrations.Dns do
  use Ecto.Migration

  @unicast_one_nip_per_name :dns_unicast_nip_unique_index
  @anycast_one_npc_per_name :dns_anycast_npc_unique_index

  def change do
    create table(:dns_unicast, primary_key: false) do
      add :network_id,
        :inet,
        primary_key: true
      add :name,
        :string,
        primary_key: true
      add :ip,
        :inet,
        null: false
    end

    create unique_index(
      :dns_unicast,
      [:network_id, :ip],
      name: @unicast_one_nip_per_name)

    create table(:dns_anycast, primary_key: false) do
      add :name,
        :string,
        primary_key: true
      add :npc_id,
        :inet,
        null: false
    end

    create unique_index(
      :dns_anycast,
      [:npc_id],
      name: @anycast_one_npc_per_name)
  end
end
