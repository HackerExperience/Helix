defmodule Helix.Process.Factory do
  use ExMachina.Ecto, repo: Helix.Process.Repo

  alias HELL.TestHelper.Random
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.Limitations
  alias Helix.Process.Model.Process.ProcessType
  alias Helix.Process.Model.Process.Resources

  alias HELL.TestHelper.Random

  defmodule DummyProcessType do
    defstruct []
  end

  # TODO: delete this one too
  defimpl ProcessType, for: DummyProcessType do
    def dynamic_resources(_),
      do: []
    def minimum(_),
      do: %{}
    def conclusion(_, process) do
      process =
        process
        |> Ecto.Changeset.change()
        |> Map.put(:action, :delete)

      {process, []}
    end
    def event(_, _, _),
      do: []
  end

  defp generate_processed do
    %Resources{
      cpu: Random.number(0..1024),
      ram: Random.number(0..1024),
      dlk: Random.number(0..1024),
      ulk: Random.number(0..1028)
    }
  end

  defp generate_allocated do
    %Resources{
      cpu: Random.number(1024..2048),
      ram: Random.number(1024..2048),
      dlk: Random.number(1024..2048),
      ulk: Random.number(1024..2048)
    }
  end

  defp generate_resources do
    %Resources{
      cpu: Random.number(4096..8192),
      ram: Random.number(4096..8192),
      dlk: Random.number(4096..8192),
      ulk: Random.number(4096..8192)
    }
  end

  def generate_limitations do
    %Limitations{
      cpu: nil,
      ram: nil,
      dlk: nil,
      ulk: nil
    }
  end

  def random_process_state,
    do: Enum.random([:running])

  def process_factory do
    %Process{
      gateway_id: Random.pk(),
      target_server_id: Random.pk(),
      process_data: %DummyProcessType{},
      file_id: Random.pk(),
      network_id: Random.pk(),
      process_type: Random.string(min: 20, max: 20),
      state: random_process_state(),
      priority: Random.number(0..5),
      objective: generate_resources(),
      processed: generate_processed(),
      allocated: generate_allocated(),
      limitations: generate_limitations(),
      creation_time: Burette.Calendar.past(),
      updated_time: DateTime.utc_now()
    }
  end
end
