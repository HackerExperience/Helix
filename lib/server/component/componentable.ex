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

  component MOBO do

    defstruct []

    def new(_mobo = %{type: :mobo}) do
      %MOBO{}
    end

    custom do

      alias Helix.Server.Component.Specable

      def check_compatibility(
        mobo_spec_id,
        component_spec_id,
        slot_id,
        used_slots)
      do
        mobo_spec = Specable.fetch(mobo_spec_id)
        component_spec = Specable.fetch(component_spec_id)

        {tentative_slot, real_id} = split_slot_id(slot_id)

        all_slots_ids =
          mobo_spec.slots
          |> Map.fetch!(component_spec.component_type)
          |> Map.keys()

        with \
          true <-
            valid_slot?(component_spec.component_type, tentative_slot)
            || {:error, :wrong_slot_type},
            # /\ The component is being linked to the correct slot type

          # The mobo has that requested slot
          true <- real_id in all_slots_ids || {:error, :bad_slot},

          # The requested slot is not being used by any other component
          true <-
            not Enum.any?(used_slots, fn {used_id, _} -> used_id == slot_id end)
            || {:error, :slot_in_use}
        do
          :ok
        end
      end

      def valid_slot?(:cpu, tentative),
        do: tentative in [:cpu]
      def valid_slot?(:hdd, tentative),
        do: tentative in [:hdd, :sata, :nvme]
      def valid_slot?(:ram, tentative),
        do: tentative in [:ram]
      def valid_slot?(:nic, tentative),
        do: tentative in [:nic]

      def split_slot_id(slot_id) when is_atom(slot_id),
        do: split_slot_id(Atom.to_string(slot_id))
      def split_slot_id("cpu_" <> id),
        do: {:cpu, id |> String.to_integer()}
      def split_slot_id("hdd_" <> id),
        do: {:hdd, id |> String.to_integer()}
      def split_slot_id("ram_" <> id),
        do: {:ram, id |> String.to_integer()}
      def split_slot_id("nic_" <> id),
        do: {:nic, id |> String.to_integer()}
    end
  end
end
