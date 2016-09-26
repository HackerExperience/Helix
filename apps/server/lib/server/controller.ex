defmodule HELM.Server.Controller do
  import Ecto.Query

  alias HELF.Broker
  alias HELM.Server

  def find_server(server_id) do
    Server.Repo.get(Server.Schema, server_id)
  end

  def new_server(id) do
    changeset = Server.Schema.create_changeset(%{server_id: id})

    case Server.Repo.insert(changeset) do
      {:ok, operation} -> {:ok, operation}
      {:error, msg} -> {:error, msg}
    end
  end

  def remove_server(server_id) do
    with server when not is_nil(server) <- find_server(server_id),
         {:ok, result} <- Server.Repo.delete(server) do
      {:ok, "The Server was removed."}
    else
      :error -> {:error, "Shit Happens"}
    end
  end

end
