defmodule HELM.Hardware.Component.Type.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Hardware
  alias HELM.Hardware.Component

  def new(component_type) do
    Component.Type.Schema.create_changeset(%{component_type: component_type})
    |> do_new_type
  end

  defp do_new_type(changeset) do
    case Hardware.Repo.insert(changeset) do
      {:ok, schema} ->
        Broker.cast("event:component:type:created", changeset.changes.component_type)
        {:ok, schema}
      {:error, changeset} ->
        {:error, changeset}
    end
  end
end
