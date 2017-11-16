defmodule Helix.Server.Componentable do

  use Helix.Server.Component.Flow

  component CPU do

    defstruct [:clock]

    def new(cpu = %{type: :cpu}) do
      %CPU{
        clock: cpu.clock
      }
    end

    resource :clock
  end

  component HDD do

    defstruct [:size, :iops]

    def new(hdd = %{type: :hdd}) do
      %HDD{
        size: hdd.size,
        iops: hdd.iops
      }
    end

    resource :size
    resource :iops
  end
end
