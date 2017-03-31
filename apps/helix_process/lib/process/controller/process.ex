defmodule Helix.Process.Controller.Process do

  import Ecto.Query, only: [where: 3]

  alias Helix.Process.Repo
  alias Helix.Process.Model.Process, as: ProcessModel

  def create(process) do
    ProcessModel.create_changeset(process)
    |> Repo.insert()
  end

  def find(process_id) do
    case Repo.get(ProcessModel, process_id) do
      nil -> {:error, :notfound}
      process -> {:ok, process}
    end
  end

  def delete(process = %ProcessModel{}),
    do: delete(process.process_id)
  def delete(process_id) do
    ProcessModel
    |> where([s], s.process_id == ^process_id)
    |> Repo.delete_all()

    :ok
  end
end
