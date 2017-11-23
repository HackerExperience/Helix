defmodule Helix.Server.Component.Specable do

  use Helix.Server.Component.Spec.Flow

  specs CPU do

    @initial :cpu_001

    def create_custom(spec, _),
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

  specs HDD do

    @initial :hdd_001

    def create_custom(spec, _),
      do: %{size: spec.size, iops: spec.iops}

    def format_custom(custom),
      do: %{size: custom["size"], iops: custom["iops"]}

    def validate_spec(data),
      do: validate_has_keys(data, [:name, :price, :slot, :size])

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

    @initial :nic_001

    def create_custom(_, custom) do
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
      do: true

    spec :NIC_001 do
      %{
        name: "BoringNic",
        price: 50,
        slot: :nic
      }
    end
  end

  specs MOBO do

    @initial :mobo_001

    def create_custom(spec, _),
      do: %{slots: spec.slots}

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

    # TODO
    def validate_spec(data) do
      true
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