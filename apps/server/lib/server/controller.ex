defmodule HELM.Server.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}

  alias HELM.Server.Repo
  alias HELM.Server.Schema, as: ServerSchema

  def create(params) do
    %{server_type: params.server_type,
      poi_id: params[:poi_id],
      motherboard_id: params[:motherboard_id]}
    |> ServerSchema.create_changeset()
    |> do_create()
  end

  def find(server_id) do
    case Repo.get_by(ServerSchema, server_id: server_id) do
      res when not is_nil(res) -> {:ok, res}
      error -> {:error, :notfound}
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

  def attach(server_id, mobo_id) do
    with {:ok, server} <- find(server_id),
         {:ok, _} <- Broker.call("hardware:get", {:motherboard, mobo_id}) do
      ServerSchema.update_changeset(server, %{motherboard_id: mobo_id})
      |> Repo.update()
    else
      error -> error
    end
  end

  def detach(server_id) do
    case find(server_id) do
      {:ok, server} ->
        ServerSchema.update_changeset(server, %{motherboard_id: nil})
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