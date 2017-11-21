defmodule Helix.Server.Component.Specable do

  use Helix.Server.Component.Spec.Flow

  specs CPU do

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

    def create_custom(_, custom) do
      %{
        ulk: custom.ulk,
        dlk: custom.dlk,
        network_id: custom.network_id |> Network.ID.cast!()
      }
    end

    def format_custom(custom) do
      %{
        ulk: custom["ulk"],
        dlk: custom["dlk"],
        network_id: custom["network_id"] |> Network.ID.cast!()
      }
    end

    # TODO is this executed before or after `create_custom`?
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

    def create_custom(spec, _),
      do: %{slots: spec.slots}

    def format_custom(custom) do
      slots =
        custom["slots"]
        |> Enum.reduce(%{}, fn {slot_id, slot_info}, acc ->
          slot_id = slot_id |> String.to_existing_atom()
          atomized_slot_info =
            %{
              type: slot_info["type"] |> String.to_existing_atom()
            }

          %{}
          |> Map.put(slot_id, atomized_slot_info)
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
