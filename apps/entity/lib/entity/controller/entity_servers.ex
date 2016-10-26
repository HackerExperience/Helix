defmodule HELM.Entity.Controller.EntityServers do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Entity.Model.Repo
  alias HELM.Entity.Model.EntityServers, as: MdlEntityServers

  def create(server_id, entity_id) do
    %{server_id: server_id, entity_id: entity_id}
    |> MdlEntityServers.create_changeset
    |> Repo.insert()
  end

  def find(server_id) do
    case Repo.get_by(MdlEntityServers, server_id: server_id) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(server_id) do
    with {:ok, server} <- find(server_id),
         {:ok, _} <- Repo.delete(server) do
      :ok
    else
      {:error, :notfound} -> :ok
    end
  end
end