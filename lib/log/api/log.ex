defmodule Helix.Log.API.Log do

  alias Helix.Log.Query.Log, as: LogQuery
  alias Helix.Software.Action.Flow.LogDeleter, as: LogDeleterFlow

  def index(server_id) do
    logs = LogQuery.get_logs_on_server(server_id)

    # HACK: FIXME: This belongs to a viewable protocol. We're doing it as it
    #   is now so it works before we do the real work (?)
    Enum.map(logs, fn log ->
      Map.take(log, [:log_id, :message, :inserted_at])
    end)
  end

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
