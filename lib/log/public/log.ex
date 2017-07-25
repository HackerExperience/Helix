defmodule Helix.Log.Public.Log do

  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.Flow.LogDeleter, as: LogDeleterFlow
  alias Helix.Log.Model.Log
  alias Helix.Log.Query.Log, as: LogQuery

  @spec index(Server.id) ::
    [map]
  def index(server_id) do
    logs = LogQuery.get_logs_on_server(server_id)

    # HACK: FIXME: This belongs to a viewable protocol. We're doing it as it
    #   is now so it works before we do the real work (?)
    Enum.map(logs, &Map.take(&1, [:log_id, :message, :inserted_at]))
  end

  @spec delete(Server.id, Server.id, Network.id, Log.id) ::
    :ok
    | {:error, :nxlog | :unknown}
  def delete(gateway_id, target_id, network_id, log_id) do
    with \
      %{server_id: ^target_id} <- LogQuery.fetch(log_id) || {:error, :nxlog},
      {:ok, _} <- LogDeleterFlow.start_process(gateway_id, network_id, log_id)
    do
      :ok
    else
      {:error, :nxlog} ->
        {:error, :nxlog}
      _ ->
        {:error, :unknown}
    end
  end
end
