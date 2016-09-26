defmodule HELM.Process.Controller do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Process

  def find_process(process_id) do
    Process.Repo.get(Process.Schema, process_id)
  end

  def new_process(process) do
    changeset = Process.Schema.create_changeset(process)

    case Process.Repo.insert(changeset) do
      {:ok, operation} -> {:ok, operation}
      {:error, msg} -> {:error, msg}
    end
  end

  def remove_process(process_id) do
    with process when not is_nil(process) <- find_process(process_id),
         {:ok, result} <- Process.Repo.delete(process) do
      {:ok, "The Process was removed."}
    else
      :error -> {:error, "Shit Happens"}
    end
  end

end
