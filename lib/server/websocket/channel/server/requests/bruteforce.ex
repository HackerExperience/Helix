defmodule Helix.Server.Websocket.Channel.Server.Requests.Bruteforce do

  require Helix.Websocket.Request

  Helix.Websocket.Request.register()

  defimpl Helix.Websocket.Requestable do

    alias HELL.IPv4
    alias Helix.Websocket.Utils, as: WebsocketUtils
    alias Helix.Network.Model.Network
    alias Helix.Software.Henforcer.File.Cracker, as: CrackerHenforcer
    alias Helix.Server.Model.Server
    alias Helix.Server.Public.Server, as: ServerPublic

    def check_params(request, socket) do
      with \
        {:ok, network_id} <-
          Network.ID.cast(request.unsafe_params["network_id"]),
        true <- IPv4.valid?(request.unsafe_params["ip"]),
        {:ok, bounces} = cast_bounces(request.unsafe_params["bounces"]),
        true <- socket.assigns.access_type == :local || :bad_attack_src
      do
        params = %{
          bounces: bounces,
          network_id: network_id,
          ip: request.unsafe_params["ip"]
        }

        {:ok, %{request| params: params}}
      else
        :bad_attack_src ->
          {:error, %{message: "bad_attack_src"}}
        _ ->
          {:error, %{message: "bad_request"}}
      end
    end

    def check_permissions(request, socket) do
      network_id = request.params.network_id
      source_id = socket.assigns.gateway.server_id
      source_ip = socket.assigns.gateway.ips[network_id]
      ip = request.params.ip

      can_bruteforce =
        CrackerHenforcer.can_bruteforce(source_id, source_ip, network_id, ip)

      case can_bruteforce do
        :ok ->
          {:ok, request}
        {:error, {:target, :self}} ->
          {:error, %{message: "target_self"}}
      end
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
