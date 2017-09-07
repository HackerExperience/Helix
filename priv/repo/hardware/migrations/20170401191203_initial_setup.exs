defmodule Helix.Hardware.Repo.Migrations.InitialSetup do
  use Ecto.Migration

  def change do
    create table(:component_types, primary_key: false) do
      add :component_type,
        :string,
        primary_key: true
    end

    create table(:component_specs, primary_key: false) do
      add :component_type,
        references(
          :component_types,
          column: :component_type,
          type: :string)
      add :spec,
        :jsonb
      add :spec_id,
        :string,
        primary_key: true

      timestamps()
    end

    create table(:components, primary_key: false) do
      add :component_type,
        references(
          :component_types,
          column: :component_type,
          type: :string)
      add :component_id,
        :inet,
        primary_key: true
      add :spec_id,
        references(
          :component_specs,
          column: :spec_id,
          type: :string)

      timestamps()
    end

    create table(:motherboards, primary_key: false) do
      add :motherboard_id,
        references(
          :components,
          column: :component_id,
          type: :inet,
          on_delete: :delete_all,
          name: :motherboards_motherboard_id_fkey),
        primary_key: true

      timestamps()
    end

    create table(:motherboard_slots) do
      add :link_component_type,
        references(
          :component_types,
          column: :component_type,
          type: :string)
      add :slot_internal_id,
        :integer
      add :slot_id,
        :inet,
        primary_key: true
      add :motherboard_id,
        references(
          :motherboards,
          column: :motherboard_id,
          type: :inet,
          on_delete: :delete_all)
      add :link_component_id,
        references(
          :components,
          column: :component_id,
          type: :inet)

      timestamps()
    end

    create table(:network_connections, primary_key: false) do
      add :network_connection_id,
        :inet,
        primary_key: true
      add :network_id,
        :inet,
        null: false

      add :ip,
        :inet,
        null: false

      add :downlink,
        :integer,
        null: false
      add :uplink,
        :integer,
        null: false
    end

    create unique_index(
      :network_connections,
      [:network_id, :ip],
      name: :network_connections_network_id_ip_unique_index)
    create constraint(
      :network_connections,
      :non_neg_downlink,
      check: "downlink >= 0")
    create constraint(
      :network_connections,
      :non_neg_uplink,
      check: "uplink >= 0")

    # HDD

    create table(:hdds, primary_key: false) do
      add :hdd_id,
        references(
          :components,
          column: :component_id,
          type: :inet,
          on_delete: :delete_all,
          name: :hdds_hdd_id_fkey),
        primary_key: true

      add :hdd_size,
        :integer,
        null: false
    end

    create constraint(:hdds, :non_neg_size, check: "hdd_size >= 0")

    # CPU

    create table(:cpus, primary_key: false) do
      add :cpu_id,
        references(
          :components,
          column: :component_id,
          type: :inet,
          on_delete: :delete_all,
          name: :cpus_cpu_id_fkey),
        primary_key: true

      add :clock,
        :integer,
        null: false
      add :cores,
        :integer,
        default: 1,
        null: false
    end

    create constraint(:cpus, :non_neg_clock, check: "clock >= 0")
    create constraint(:cpus, :positive_cores, check: "cores >= 1")

    # RAM

    create table(:rams, primary_key: false) do
      add :ram_id,
        references(
          :components,
          column: :component_id,
          type: :inet,
          on_delete: :delete_all,
          name: :rams_ram_id_fkey),
        primary_key: true

      add :ram_size,
        :integer,
        null: false
    end

    create constraint(:rams, :non_neg_size, check: "ram_size >= 0")

    # NIC

    create table(:nics, primary_key: false) do
      add :nic_id,
        references(
          :components,
          column: :component_id,
          type: :inet,
          on_delete: :delete_all,
          name: :nics_nic_id_fkey),
        primary_key: true
      add :network_connection_id,
        references(
          :network_connections,
          column: :network_connection_id,
          type: :inet,
          on_delete: :nilify_all,
          name: :nics_network_connection_id_fkey)

      add :mac_address,
        :macaddr,
        null: false
    end

    create unique_index(:nics, :mac_address, name: :nics_mac_address_index)

    # MotherboardSlot

    # Ensure that a component can only be linked to one slot at a time, also
    # allows quick index scan to find if a component is being used
    create unique_index(
      :motherboard_slots,
      :link_component_id,
      name: :motherboard_slots_link_component_id_index)
    # Motherboard_slots are also fetched by their relation with parent
    # motherboard
    create index(:motherboard_slots, :motherboard_id)
  end
end
