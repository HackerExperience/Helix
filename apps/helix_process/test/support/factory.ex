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
      processed: build(:resources),
      allocated: build(:resources),
      limitations: build(:limitations),
      creation_time: Burette.Calendar.datetime(),
      updated_time: DateTime.utc_now()
    }
  end

  def resources_factory do
    %Resources{
      cpu: Random.number(0..100),
      ram: Random.number(0..1024),
      dlk: Random.number(0..100),
      ulk: Random.number(0..100)
    }
  end

  def limitations_factory do
    %Limitations{
      cpu: Random.number(100..200),
      ram: Random.number(1024..4096),
      dlk: Random.number(100..1000),
      ulk: Random.number(100..1000)
    }
  end

  defp random_process_state,
    do: Enum.random([:standby, :paused, :running, :complete])
end
