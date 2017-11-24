defmodule Helix.Server.Componentable do

  use Helix.Server.Component.Flow

  component CPU do

    alias Helix.Server.Model.Component

    @type custom :: %{clock: pos_integer}

    @spec new(Component.cpu) ::
      custom
    def new(cpu = %{type: :cpu}) do
      %{
        clock: cpu.custom.clock
      }
    end
  end

  component RAM do

    alias Helix.Server.Model.Component

    @type custom :: %{clock: pos_integer, size: pos_integer}

    @spec new(Component.ram) ::
      custom
    def new(ram = %{type: :ram}) do
      %{
        clock: ram.custom.clock,
        size: ram.custom.size
      }
    end
  end

  component HDD do

    alias Helix.Server.Model.Component

    @type custom :: %{size: pos_integer, iops: pos_integer}

    @spec new(Component.hdd) ::
      custom
    def new(hdd = %{type: :hdd}) do
      %{
        size: hdd.custom.size,
        iops: hdd.custom.iops
      }
    end
  end

  component NIC do

    alias Helix.Network.Model.Network
    alias Helix.Server.Model.Component

    # NIC custom may be temporarily "wrong", i.e. when it does not have any
    # NC assigned to it
    @type custom ::
      %{Network.id => speed_info}
      | %{network_id: Network.id, ulk: pos_integer, dlk: pos_integer}

    @type speed_info :: %{dlk: pos_integer, ulk: pos_integer}

    @spec new(Component.nic) ::
      custom
    def new(nic = %{type: :nic}) do
      speed_info = %{dlk: nic.custom.dlk, ulk: nic.custom.ulk}
      network_id = nic.custom.network_id

      %{}
      |> Map.put(network_id, speed_info)
    end
  end

  component MOBO do

    alias HELL.Constant
    alias Helix.Server.Component.Specable
    alias Helix.Server.Model.Component
    alias Helix.Server.Model.Motherboard

    @type custom :: %{}

    @type slot_id :: Constant.t
    @type slot_real_id :: non_neg_integer
    @type slot_type :: :cpu | :hdd | :sata | :nvme | :ram | :nic

    @spec new(Component.mobo) ::
      custom
    def new(_mobo = %{type: :mobo}) do
      %{}
    end

    @spec check_compatibility(
      Specable.MOBO.id, Component.Spec.id, slot_id, [Motherboard.slot])
    ::
      :ok
      | {:error, :wrong_slot_type}
      | {:error, :slot_in_use}
      | {:error, :bad_slot}
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

    @spec valid_slot?(slot_type, atom) ::
      boolean
    def valid_slot?(:cpu, tentative),
      do: tentative in [:cpu]
    def valid_slot?(:hdd, tentative),
      do: tentative in [:hdd, :sata, :nvme]
    def valid_slot?(:ram, tentative),
      do: tentative in [:ram]
    def valid_slot?(:nic, tentative),
      do: tentative in [:nic]

    @spec split_slot_id(slot_id | String.t) ::
      {slot_type, slot_real_id}
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
