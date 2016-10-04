defmodule HELM.Server.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Server

  def find(server_id) do
    case Server.Repo.get_by(Server.Schema, server_id: server_id) do
      nil -> {:error, Error.format_reply(:not_found, "No Entity found with given")}
      res -> {:ok, res}
    end
  end

  def new_server(params) do
    new(params)
  end

  defp new(params) do
    changeset = Server.Schema.create_changeset(params)

    IO.inspect changeset

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
