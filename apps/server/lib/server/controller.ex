defmodule HELM.Server.Controller do
  import Ecto.Query

  alias HELF.{Broker, Error}

  alias HELM.Server.Repo
  alias HELM.Server.Schema, as: ServerSchema

  def create(entity_id, server_type) do
    %{entity_id: entity_id, server_type: server_type}
    |> ServerSchema.create_changeset
    |> do_create
  end

  def create(params) do
    %{entity_id: params.entity_id,
      server_type: params.server_type,
      poi_id: params[:poi_id],
      motherboard_id: params[:motherboard_id]}
    |> ServerSchema.create_changeset
    |> do_create
  end

  def find(server_id) do
    case Repo.get_by(ServerSchema, server_id: server_id) do
      res when not is_nil(res) -> {:ok, res}
      error -> {:error, "Server not found."}
    end
  end

  def attach(server_id, mobo_id) do
    with {:ok, server} <- find(server_id),
         {:ok, _} <- Broker.call("hardware:get", {:motherboard, mobo_id}) do
      ServerSchema.update_changeset(server, %{motherboard_id: mobo_id})
      |> do_update
    else
      error -> error
    end
  end

  def detach(server_id) do
    case find(server_id) do
      {:ok, server} ->
        ServerSchema.update_changeset(server, %{motherboard_id: nil})
        |> do_update
      error -> error
    end
  end

  def delete(server_id) do
    case find(server_id) do
      {:ok, server_id} -> do_delete(server_id)
      error -> error
    end
  end

  defp do_create(changeset) do
    case Repo.insert(changeset) do
      {:ok, result} ->
        Broker.cast("event:server:created", result.server_id)
        {:ok, result}
      error -> error
    end
  end

  defp do_update(changeset) do
    case Repo.update(changeset) do
      {:ok, schema} -> {:ok, schema}
      error -> error
    end
  end

  defp do_delete(server) do
    case Repo.delete(server) do
      {:ok, result} -> {:ok, result}
      error -> error
    end
  end
end
