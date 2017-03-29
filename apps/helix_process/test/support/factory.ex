defmodule Helix.Process.Factory do
  use ExMachina.Ecto, repo: Helix.Process.Repo

  alias HELL.TestHelper.Random
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.Limitations
  alias Helix.Process.Model.Process.ProcessType
  alias Helix.Process.Model.Process.Resources

  alias HELL.TestHelper.Random

  defmodule NaiveProcessType do
    defstruct []
  end

  defimpl ProcessType, for: NaiveProcessType do
    def dynamic_resources(_),
      do: []

    def event_namespace(_),
      do: nil
  end

  defp generate_processed do
    params = [
      cpu: Random.number(0..1024),
      ram: Random.number(0..1024),
      dlk: Random.number(0..1024),
      ulk: Random.number(0..1028)
    ]

    build(:resources, params)
  end

  defp generate_allocated do
    params = [
      cpu: Random.number(1024..2048),
      ram: Random.number(1024..2048),
      dlk: Random.number(1024..2048),
      ulk: Random.number(1024..2048)
    ]

    build(:resources, params)
  end

  def random_process_state,
    do: Enum.random([:standby, :paused, :running, :complete])

  def process_factory do
    %Process{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %NaiveProcessType{},
      file_id: Random.pk(),
      network_id: Random.pk(),
      process_type: Random.string(min: 20, max: 20),
      state: random_process_state(),
      priority: Random.number(0..5),
      objective: build(:resources),
      processed: generate_processed(),
      allocated: generate_allocated(),
      limitations: build(:limitations),
      creation_time: Burette.Calendar.past(),
      updated_time: DateTime.utc_now()
    }
  end

  def resources_factory do
    %Resources{
      cpu: Random.number(4096..8192),
      ram: Random.number(4096..8192),
      dlk: Random.number(4096..8192),
      ulk: Random.number(4096..8192)
    }
  end

  def limitations_factory do
    %Limitations{
      cpu: nil,
      ram: nil,
      dlk: nil,
      ulk: nil
    }
  end
end
