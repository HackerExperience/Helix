defmodule Helix.Server.Component.Specable do
  @moduledoc """
  `Specable` is the foundation for a component; it defines exactly what
  resources each component has, as well as the price (baseline).

  `Specable` is based on `spec_ids`. A spec contains all required information
  for the game to generate the component, figure out its resource and how to
  work with it.

  Each component may have its own custom fields on the `spec` map. All specs
  (and therefore all components) of the game are defined here.
  """

  use Helix.Server.Component.Spec.Flow

  specs CPU do

    @type spec ::
      %{
        spec_id: id,
        component_type: :cpu,
        name: String.t,
        price: pos_integer,
        slot: slot,
        clock: pos_integer
      }

    @type id ::
      :cpu_001

    @type slot :: :cpu

    @initial :cpu_001

    def create_custom(spec),
      do: %{clock: spec.clock}

    def format_custom(custom),
      do: %{clock: custom["clock"]}

    def validate_spec(data),
      do: validate_has_keys(data, [:name, :price, :slot, :clock])

    spec :CPU_001 do
      %{
        name: "Threadisaster",
        price: 100,
        slot: :cpu,

        clock: 256
      }
    end
  end

  specs RAM do

    @type spec ::
      %{
        spec_id: id,
        component_type: :ram,
        name: String.t,
        price: pos_integer,
        slot: slot,
        clock: pos_integer,
        size: pos_integer
      }

    @type id ::
      :ram_001

    @type slot :: :ram

    @initial :ram_001

    def create_custom(spec),
      do: %{clock: spec.clock, size: spec.size}

    def format_custom(custom),
      do: %{clock: custom["clock"], size: custom["size"]}

    def validate_spec(data),
      do: validate_has_keys(data, [:name, :price, :clock, :size])

    spec :RAM_001 do
      %{
        name: "RAM Na Montana",
        price: 100,
        slot: :ram,

        clock: 100,
        size: 256
      }
    end
  end

  specs HDD do

    @type spec ::
      %{
        spec_id: id,
        component_type: :hdd,
        name: String.t,
        price: pos_integer,
        slot: slot,
        size: pos_integer,
        iops: pos_integer
      }

    @type slot :: :sata | :nvme

    @type id ::
      :hdd_001

    @initial :hdd_001

    def create_custom(spec),
      do: %{size: spec.size, iops: spec.iops}

    def format_custom(custom),
      do: %{size: custom["size"], iops: custom["iops"]}

    def validate_spec(data),
      do: validate_has_keys(data, [:name, :price, :slot, :size, :iops])

    spec :HDD_001 do
      %{
        name: "SemDisk",
        price: 150,
        slot: :sata,

        size: 1024,
        iops: 1000
      }
    end
  end

  specs NIC do

    alias Helix.Network.Model.Network
    alias Helix.Network.Query.Network, as: NetworkQuery

    @type spec ::
      %{
        spec_id: id,
        component_type: :nic,
        name: String.t,
        price: pos_integer,
        slot: slot,
        dlk: pos_integer,
        ulk: pos_integer,
        network_id: Network.id
      }

    @type slot :: :nic

    @type id ::
      :nic_001

    @initial :nic_001

    def create_custom(_) do
      %{
        ulk: 0,
        dlk: 0,
        network_id: NetworkQuery.internet().network_id
      }
    end

    def format_custom(custom = %{"network_id" => _, "dlk" => _, "ulk" => _}) do
      %{
        ulk: custom["ulk"],
        dlk: custom["dlk"],
        network_id: custom["network_id"] |> Network.ID.cast!()
      }
    end
    def format_custom(_),
      do: %{}

    def validate_spec(data),
      do: validate_has_keys(data, [:name, :price, :slot])

    spec :NIC_001 do
      %{
        name: "BoringNic",
        price: 50,
        slot: :nic
      }
    end
  end

  specs MOBO do

    @type spec ::
      %{
        spec_id: id,
        component_type: :mobo,
        name: String.t,
        price: pos_integer,
        slots: slots
      }

    @type slots ::
      %{
        cpu: slot_entries,
        ram: slot_entries,
        hdd: slot_entries,
        nic: slot_entries,
        usb: slot_entries,
      }

    @type slot_entries ::
      %{integer => slot_info}

    @type slot_info :: %{}

    @type id ::
      :mobo_001
      | :mobo_002
      | :mobo_999

    @typedoc """
    Below type is mostly to register the atom on the VM, so we can safely use
    `String.to_existing_atom` when converting an external input.
    """
    @type slot_id ::
      :cpu_0 | :cpu_1 | :cpu_2 | :cpu_3 | :cpu_4 | :cpu_5 | :cpu_6 | :cpu_7 |
      :hdd_0 | :hdd_1 | :hdd_2 | :hdd_3 | :hdd_4 | :hdd_5 | :hdd_6 | :hdd_7 |
      :ram_0 | :ram_1 | :ram_2 | :ram_3 | :ram_4 | :ram_5 | :ram_6 | :ram_7 |
      :nic_0 | :nic_1 | :nic_2 | :nic_3 | :usb_0 | :usb_1 | :usb_2 | :usb_3

    @initial :mobo_001

    def create_custom(spec),
      do: %{slots: spec.slots}

    @doc """
    Converts the mobo slots defined on the spec to a format used by Helix,
    which is :<component_type>_<real_id>. So slot `0` for `hdd` is `:hdd_0`.
    """
    def format_custom(custom) do
      slots =
        custom["slots"]
        |> Enum.reduce(%{}, fn {slot_type, slots}, acc ->
          slot_type = slot_type |> String.to_existing_atom()

          slot_data =
            Enum.reduce(slots, %{}, fn {slot_id, _slot_info}, acc ->
              slot_id = slot_id |> String.to_integer()

              %{}
              |> Map.put(slot_id, %{})
              |> Map.merge(acc)
            end)

          %{}
          |> Map.put(slot_type, slot_data)
          |> Map.merge(acc)
        end)

      %{slots: slots}
    end

    def validate_spec(data) do
      validate_has_keys(data.slots, [:cpu, :ram, :hdd, :nic, :usb])
      && validate_has_keys(data, [:price, :name])
    end

    spec :MOBO_001 do
      %{
        name: "Mobo1",
        price: 100,

        slots: %{
          cpu: %{0 => %{}},
          ram: %{0 => %{}},
          hdd: %{0 => %{}},
          nic: %{0 => %{}},
          usb: %{}
        }
      }
    end

    spec :MOBO_002 do
      %{
        name: "Mobo1",
        price: 200,

        slots: %{
          cpu: %{0 => %{}, 1 => %{}},
          ram: %{0 => %{}, 1 => %{}},
          hdd: %{0 => %{}},
          nic: %{0 => %{}},
          usb: %{0 => %{}}
        }
      }
    end

    spec :MOBO_999 do
      %{
        name: "Mobotastic",
        price: 999_999_999,

        slots: %{
          cpu: %{0 => %{}, 1 => %{}, 2 => %{}, 3 => %{}},
          ram: %{0 => %{}, 1 => %{}, 2 => %{}, 3 => %{}},
          hdd: %{0 => %{}, 1 => %{}, 2 => %{}, 3 => %{}},
          nic: %{0 => %{}, 1 => %{}, 2 => %{}, 3 => %{}},
          usb: %{0 => %{}, 1 => %{}, 2 => %{}, 3 => %{}}
        }
      }
    end
  end
end
