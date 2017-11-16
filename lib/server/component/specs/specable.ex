defmodule Helix.Server.Component.Specable do

  use Helix.Server.Component.Spec.Flow

  specs CPU do

    def get_custom(spec),
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

    def get_custom(spec),
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
end
