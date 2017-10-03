defmodule Helix.Test.Process.TOPHelper do

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.ProcessType
  alias Helix.Process.State.TOP.Manager, as: TOPManager
  alias Helix.Process.State.TOP.Server, as: TOPServer
  alias Helix.Process.Repo, as: ProcessRepo

  def top_stop(server) do
    server
    |> Server.ID.cast!()
    |> TOPManager.get()
    |> its_time_to_stop()

    # Sync TOP events. Required after apply.
    :timer.sleep(50)
  end

  defp its_time_to_stop(nil),
    do: :ok
  defp its_time_to_stop(pid),
    do: GenServer.stop(pid)

  def force_completion(process) do
    finished_process = mark_as_finished(process)

    process.gateway_id
    |> TOPManager.get()
    |> TOPServer.reset_processes([finished_process])

    # Sync TOP events. Required after apply.
    :timer.sleep(50)
  end

  defp mark_as_finished(process) do
    %{process| processed: process.objective}
    |> Ecto.Changeset.change()
    |> ProcessRepo.update!()
  end

  def soft_complete(process = %Process{}) do
    cs = Changeset.change(process)
    ProcessType.state_change(process.process_data, cs, :running, :complete)
  end

  def soft_kill(process = %Process{}, reason \\ :normal) do
    cs = Changeset.change(process)
    ProcessType.kill(process.process_data, cs, reason)
  end
end
