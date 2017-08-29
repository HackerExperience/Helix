defmodule Helix.Test.Process.TOPHelper do

  alias Helix.Server.Model.Server
  alias Helix.Process.State.TOP.Manager, as: TOPManager
  alias Helix.Process.State.TOP.Server, as: TOPServer
  alias Helix.Process.Repo, as: ProcessRepo

  def top_stop(server) do
    server
    |> Server.ID.cast!()
    |> TOPManager.get()
    |> its_time_to_stop()

    # Sync TOP events
    :timer.sleep(50)
  end

  defp its_time_to_stop(nil),
    do: :ok
  defp its_time_to_stop(pid),
    do: GenServer.stop(pid)

  def force_completion(server_id, process) do
    finished_process = mark_as_finished(process)

    server_id
    |> TOPManager.get()
    |> TOPServer.reset_processes([finished_process])

    :timer.sleep(50)
  end

  defp mark_as_finished(process) do
    %{process| processed: process.objective}
    |> Ecto.Changeset.change()
    |> ProcessRepo.update!()
  end
end
