defmodule Helix.Account.Websocket.Channel.Account.Requests.Bootstrap do

  require Helix.Websocket.Request

  Helix.Websocket.Request.register()

  defimpl Helix.Websocket.Requestable do

    def check_params(request, _socket),
      do: {:ok, request}

    def check_permissions(request, _socket),
      do: {:ok, request}

    def handle_request(request, socket) do
      
    end

    def handle_request(request, socket) do
      source_id = socket.assigns.gateway.server_id
      network_id = request.params.network_id
      ip = request.params.ip
      bounces = request.params.bounces

      case ServerPublic.bruteforce(source_id, network_id, ip, bounces) do
        {:ok, process} ->
          meta = %{process: process}

          {:ok, %{request| meta: meta}}

        # HACK: Workaround for https://github.com/elixir-lang/elixir/issues/6426
        error = {_, m} ->
          if Map.has_key?(m, :message) do
            error
          else
            {:error, %{message: "internal"}}
          end
        # error = {:error, %{message: _}} ->
        #   error
        # _ ->
        #   {:error, %{message: "internal"}}
      end
    end

    def reply(request, socket) do
      process = request.meta.process

      file_id = process.file_id && to_string(process.file_id)
      connection_id = process.connection_id && to_string(process.connection_id)

      data = %{
        process_id: to_string(process.process_id),
        type: to_string(process.process_type),
        network_id: to_string(process.network_id),
        file_id: file_id,
        connection_id: connection_id,
        source_ip: socket.assigns.gateway.ips[process.network_id],
        target_ip: request.params.ip
      }

      WebsocketUtils.reply_ok(data, socket)
    end

    defp cast_bounces(bounces) when is_list(bounces),
      do: {:ok, Enum.map(bounces, &(Server.ID.cast!(&1)))}
    defp cast_bounces(_),
      do: :error
  end
end
