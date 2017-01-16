defmodule Helix.Process.Controller.Process do

  import Ecto.Query, only: [where: 3]

  alias Helix.Process.Repo
  alias Helix.Process.Model.Process, as: MdlProcess

  def create(process) do
    MdlProcess.create_changeset(process)
    |> Repo.insert()
  end

  def find(process_id) do
    case Repo.get(MdlProcess, process_id) do
      nil -> {:error, :notfound}
      process -> {:ok, process}
    end
  end

  def delete(process_id) do
    MdlProcess
    |> where([s], s.process_id == ^process_id)
    |> Repo.delete_all()

    :ok
  end
end