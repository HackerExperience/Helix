defmodule HELM.Server.Controller.ServerTypes do
  import Ecto.Query

  alias HELF.{Broker, Error}
  alias HELM.Server.Model.Repo
  alias HELM.Server.Model.ServerTypes, as: MdlServerTypes

  def create(server_type) do
    MdlServerTypes.create_changeset(%{server_type: server_type})
    |> Repo.insert()
  end

  def find(server_type) do
    case Repo.get_by(MdlServerTypes, server_type: server_type) do
      nil -> {:error, :notfound}
      res -> {:ok, res}
    end
  end

  def delete(server_type) do
    MdlServerTypes
    |> where([s], s.server_type == ^server_type)
    |> Repo.delete_all()

    :ok
  end

  def all do
    MdlServerTypes
    |> select([t], t.server_type)
    |> Repo.all()
  end
end