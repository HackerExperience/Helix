defmodule Helix.Hardware.Repo.Migrations.AddComponentSpecialization do
  use Ecto.Migration

  def change do
    # HDD

    create table(:hdds, primary_key: false) do
      add :hdd_id, references(:components, column: :component_id, type: :inet, on_delete: :delete_all, name: :hdds_hdd_id_fkey), primary_key: true

      add :hdd_size, :integer, null: false
    end

    create constraint(:hdds, :non_neg_size, check: "hdd_size >= 0")

    # CPU

    create table(:cpus, primary_key: false) do
      add :cpu_id, references(:components, column: :component_id, type: :inet, on_delete: :delete_all, name: :cpus_cpu_id_fkey), primary_key: true

      add :clock, :integer, null: false
      add :cores, :integer, default: 1, null: false
    end

    create constraint(:cpus, :non_neg_clock, check: "clock >= 0")
    create constraint(:cpus, :positive_cores, check: "cores >= 1")

    # RAM

    create table(:rams, primary_key: false) do
      add :ram_id, references(:components, column: :component_id, type: :inet, on_delete: :delete_all, name: :rams_ram_id_fkey), primary_key: true

      add :ram_size, :integer, null: false
    end

    create constraint(:rams, :non_neg_size, check: "ram_size >= 0")

    # NIC

    create table(:nics, primary_key: false) do
      add :nic_id, references(:components, column: :component_id, type: :inet, on_delete: :delete_all, name: :nics_nic_id_fkey), primary_key: true

      add :mac_address, :macaddr, null: false
      add :downlink, :integer, null: false
      add :uplink, :integer, null: false
    end

    create constraint(:nics, :non_neg_downlink, check: "downlink >= 0")
    create constraint(:nics, :non_neg_uplink, check: "uplink >= 0")
    create unique_index(:nics, :mac_address, name: :nics_mac_address_index)

    # Note that temporarily each NIC can only have one IP. As soon as "networks"
    # are implemented, a NIC will be able to have more than one IP and those IPs
    # will be bound to different networks (eg: public internet and LAN)
    create table(:nic_ips, primary_key: false) do
      add :nic_id, references(:nics, column: :nic_id, type: :inet, on_delete: :delete_all, name: :nic_ips_nic_id_fkey), primary_key: true

      add :ip, :inet, null: false
    end

    # As soon as we correctly implement the "networks" feature this should be
    # replaced by a unique index like {network, ip}
    create unique_index(:nic_ips, :ip, name: :nic_ips_ip_index)

    # MotherboardSlot

    # Ensure that a component can only be linked to one slot at a time, also
    # allows quick index scan to find if a component is being used
    create unique_index(:motherboard_slots, :link_component_id, name: :motherboard_slots_link_component_id_index)
    # Motherboard_slots are also fetched by their relation with parent
    # motherboard
    create index(:motherboard_slots, :motherboard_id)
  end
end