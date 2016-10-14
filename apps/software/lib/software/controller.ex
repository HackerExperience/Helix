defmodule HELM.Software.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}

  alias HELM.Software.Repo
  alias HELM.Software.Schema, as: SoftwareSchema

  def create() do
  end

  def create(params) do
  end

  def find() do
  end

  def delete() do
    case find() do
      {:ok, software} -> do_delete(software)
      error -> error
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end

  defp do_update(changeset) do
    case Repo.update(changeset) do
      {:ok, schema} -> {:ok, schema}
      error -> error
    end
  end

  defp do_delete(software) do
    case Repo.delete(software) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end
end
