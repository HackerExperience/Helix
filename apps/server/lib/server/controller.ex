defmodule HELM.Server.Controller do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Server

  def find_server(server_id) do
    Server.Repo.get(Server.Schema, server_id)
  end

  def new_server(params) do
    new(params)
  end

  defp new(params) do
    changeset = Server.Schema.create_changeset(params)

    case Server.Repo.insert(changeset) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end

  def update_motherboard(server_id, motherboard_id) do
    update(%{server_id: server_id, motherboard_id: motherboard_id})
  end

  def update_poi(server_id, poi_id) do
    update(%{server_id: server_id, poi_id: poi_id})
  end

  defp update(params) do
    changeset = Server.Schema.update_changeset(params)

    case Server.Repo.update(changeset) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end

  def remove_server(server_id) do
    case Server.Repo.delete(%{server_id: server_id}) do
      {:ok, result} -> {:ok, result}
      {:error, msg} -> {:error, msg}
    end
  end
end
