defmodule Helix.Process.Internal.Process do

  alias Helix.Process.Repo
  alias Helix.Process.Model.Process

  @spec fetch(Process.id) ::
    Process.t
    | nil
  def fetch(process_id),
    do: Repo.get(Process, process_id)

  @spec delete(Process.t | Process.id) ::
    :ok
  def delete(process = %Process{}),
    do: delete(process.process_id)
  def delete(process_id) do
    process_id
    |> Process.Query.by_id()
    |> Repo.delete_all()

    :ok
  end
end
