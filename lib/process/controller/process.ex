defmodule Helix.Process.Controller.Process do

  alias HELL.PK
  alias Helix.Process.Repo
  alias Helix.Process.Model.Process
  alias Helix.Process.Model.Process.ProcessCreatedEvent

  @spec create(map) ::
    {:ok, Process.t, [event :: struct]}
    | {:error, Ecto.Changeset.t}
  def create(process) do
    changeset = Process.create_changeset(process)

    with {:ok, process} <- Repo.insert(changeset) do
      event = %ProcessCreatedEvent{
        process_id: process.process_id,
        gateway_id: process.gateway_id,
        target_id: process.target_server_id
      }

      {:ok, process, [event]}
    end
  end

  @spec fetch(PK.t) :: Process.t | nil
  def fetch(process_id),
    do: Repo.get(Process, process_id)

  @spec delete(Process.t | PK.t) :: no_return
  def delete(process = %Process{}),
    do: delete(process.process_id)
  def delete(process_id) do
    process_id
    |> Process.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end
