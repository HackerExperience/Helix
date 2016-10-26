defmodule HELM.Process.Controller.Processes do
  import Ecto.Query

  alias HELM.Process.Model.Repo
  alias HELM.Process.Model.Processes, as: MdlProcesses

  def create(process) do
    MdlProcesses.create_changeset(process)
    |> Repo.insert()
  end

  def find(process_id) do
    case Repo.get(MdlProcesses, process_id) do
      nil -> {:error, :notfound}
      process -> {:ok, process}
    end
  end

  def delete(process_id) do
    MdlProcesses
    |> where([s], s.process_id == ^process_id)
    |> Repo.delete_all()

    :ok
  end
end