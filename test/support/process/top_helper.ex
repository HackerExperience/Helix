defmodule Helix.Test.Process.TOPHelper do

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Processable
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.Repo, as: ProcessRepo
  alias Helix.Process.State.TOP.Manager, as: TOPManager
  alias Helix.Process.State.TOP.Server, as: TOPServer

  @doc """
  Stops the TOP of a server.
  """
  def top_stop(server = %Server{}),
    do: top_stop(server.server_id)
  def top_stop(server_id = %Server.ID{}) do
    server_id
    |> TOPManager.get()
    |> its_time_to_stop()

    # Sync TOP events. Required after apply.
    :timer.sleep(50)
  end

  defp its_time_to_stop(nil),
    do: :ok
  defp its_time_to_stop(pid),
    do: GenServer.stop(pid)

  @doc """
  Completes the process, emitting the related events and removing from the db.
  """
  def force_completion(process_id = %Process.ID{}) do
    process_id
    |> ProcessQuery.fetch()
    |> force_completion()
  end
  def force_completion(process = %Process{}) do
    finished_process = mark_as_finished(process)

    process.gateway_id
    |> TOPManager.get()
    |> TOPServer.reset_processes([finished_process])

    # Sync TOP events. Required after apply.
    :timer.sleep(50)
  end

  @doc """
  Runs the logic that would be ran if the process was completed, but does not
  actually modify the database, nor emit the conclusion events.
  """
  def soft_complete(process = %Process{}) do
    cs = Changeset.change(process)
    Processable.state_change(process.process_data, cs, :running, :complete)
  end

  @doc """
  Simulates the `kill` of a process, executing the `Processable` relevant code.
  It won't update the status on DB, nor emit events about the kill.
  """
  def soft_kill(process = %Process{}, reason \\ :normal) do
    cs = Changeset.change(process)
    Processable.kill(process.process_data, cs, reason)
  end

  defp mark_as_finished(process) do
    %{process| processed: process.objective}
    |> Ecto.Changeset.change()
    |> ProcessRepo.update!()
  end
end
