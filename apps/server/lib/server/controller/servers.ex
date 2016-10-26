defmodule HELM.Server.Controller.Servers do
  import Ecto.Query

  alias HELF.Broker

  alias HELM.Server.Model.Repo
  alias HELM.Server.Model.Servers, as: MdlServers

  def create(params) do
    %{server_type: params.server_type,
      poi_id: params[:poi_id],
      motherboard_id: params[:motherboard_id]}
    |> MdlServers.create_changeset()
    |> do_create()
  end

  def find(server_id) do
    case Repo.get_by(MdlServers, server_id: server_id) do
      nil -> {:error, :notfound}
      server -> {:ok, server}
    end
  end

  def delete(server_id) do
    MdlServers
    |> where([s], s.server_id == ^server_id)
    |> Repo.delete_all()
    :ok
  end

  def attach(server_id, mobo_id) do
    with {:ok, server} <- find(server_id),
         {:ok, _} <- Broker.call("hardware:get", {:motherboard, mobo_id}) do
      MdlServers.update_changeset(server, %{motherboard_id: mobo_id})
      |> Repo.update()
    else
      error -> error
    end
  end

  def detach(server_id) do
    case find(server_id) do
      {:ok, server} ->
        MdlServers.update_changeset(server, %{motherboard_id: nil})
        |> Repo.update()
      error -> error
    end
  end

  defp do_create(changeset) do
    with {:ok, result} <- Repo.insert(changeset) do
      Broker.cast("event:server:created", result.server_id)
      {:ok, result}
    end
  end
end