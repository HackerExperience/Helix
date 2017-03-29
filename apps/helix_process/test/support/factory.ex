defmodule Helix.Process.Factory do
  use ExMachina.Ecto, repo: Helix.Process.Repo

  alias HELL.PK
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.ProcessType
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File

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
    now = DateTime.utc_now()

    %Process{
      gateway_id: PK.pk_for(Process),
      target_server_id: PK.pk_for(Server),
      file_id: PK.pk_for(File),
      network_id: Random.pk(),
      software: %{},
      process_type: Random.string(min: 20, max: 20),
      state: random_process_state(),
      priority: Random.number(0..3),
      processed: %{},
      allocated: %{},
      limitations: %{},
      creation_time: now,
      updated_time: now
    }
  end

  defp random_process_state,
    do: Enum.random([:standby, :paused, :running, :complete])
end
