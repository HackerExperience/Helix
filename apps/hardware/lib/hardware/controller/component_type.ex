defmodule HELM.Hardware.Controller.ComponentType do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Hardware.Repo
  alias HELM.Hardware.Model.ComponentType, as: MdlCompType

  def create(component_type) do
    MdlCompType.create_changeset(%{component_type: component_type})
    |> do_create()
  end

  def find(component_type) do
    case Repo.get_by(MdlCompType, component_type: component_type) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def all do
    MdlCompType
    |> select([t], t.component_type)
    |> Repo.all()
  end

  def delete(component_type) do
    MdlCompType
    |> where([s], s.component_type == ^component_type)
    |> Repo.delete_all()

    :ok
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:type:created", schema.component_type)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end