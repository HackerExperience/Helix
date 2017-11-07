defmodule Helix.Test.Process.TOPHelper do

  alias Ecto.Changeset
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Processable
  alias Helix.Process.Query.Process, as: ProcessQuery
  alias Helix.Process.Repo, as: ProcessRepo

  alias Helix.Process.Action.TOP, as: TOPAction

  @doc """
  Stops the TOP of a server.
  """
  def top_stop(_) do
    # noop (Legacy call from previous TOP implementation)
    # Left as a gentle reminder of those days of yore
  end

  @doc """
  Completes the process, emitting the related events and removing from the db.
  """
  def force_completion(process_id = %Process.ID{}) do
    process_id
    |> ProcessQuery.fetch()
    |> force_completion()
  end
  def force_completion(process = %Process{}) do
    # Update the DB process entry, now it has magically reached its objective
    process
    |> Changeset.change()
    |> Changeset.put_change(:allocated, %{})  # Avoids `:waiting_alloc` status
    |> Changeset.put_change(:processed, process.objective)
    |> ProcessRepo.update()

    # Force a recalque on the server
    TOPAction.recalque(process)
  end

  @doc """
  Runs the logic that would be ran if the process was completed, but does not
  actually modify the database, nor emit the conclusion events.
  """
  def soft_complete(process = %Process{}) do
    Processable.complete(process.data, process)
  end

  @doc """
  Simulates the `kill` of a process, executing the `Processable` relevant code.
  It won't update the status on DB, nor emit events about the kill.
  """
  def soft_kill(process = %Process{}, reason \\ :normal) do
    Processable.kill(process.data, process, reason)
  end
end
