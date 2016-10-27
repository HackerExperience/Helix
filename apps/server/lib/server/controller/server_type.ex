defmodule HELM.Server.Controller.ServerType do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Server.Repo
  alias HELM.Server.Model.ServerType, as: MdlServerType

  def create(server_type) do
    MdlServerType.create_changeset(%{server_type: server_type})
    |> Repo.insert()
  end

  def find(server_type) do
    case Repo.get_by(MdlServerType, server_type: server_type) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(server_type) do
    MdlServerType
    |> where([s], s.server_type == ^server_type)
    |> Repo.delete_all()

    :ok
  end

  def all do
    MdlServerType
    |> select([t], t.server_type)
    |> Repo.all()
  end
end