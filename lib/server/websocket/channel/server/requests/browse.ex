defmodule Helix.Server.Websocket.Channel.Server.Requests.Browse do

  require Helix.Websocket.Request

  Helix.Websocket.Request.register()

  defimpl Helix.Websocket.Requestable do

    alias Helix.Websocket.Utils, as: WebsocketUtils
    alias Helix.Network.Model.Network
    alias Helix.Network.Henforcer.Network, as: NetworkHenforcer
    alias Helix.Server.Model.Server
    alias Helix.Server.Public.Server, as: ServerPublic

    def check_params(request, socket) do
      gateway_id = socket.assigns.gateway.server_id
      destination_id = socket.assigns.destination.server_id

      origin_id =
        if Map.has_key?(request.unsafe, "origin") do
          request.unsafe["origin"]
        else
          socket.assigns.destination.server_id
        end

      with \
        {:ok, network_id} <-
          Network.ID.cast(request.unsafe["network_id"]),
        {:ok, origin_id} <- Server.ID.cast(origin_id),
        true <-
          NetworkHenforcer.valid_origin?(origin_id, gateway_id, destination_id)
          || :badorigin
      do
        validated_params = %{
          network_id: network_id,
          address: request.unsafe["address"],
          origin: origin_id
        }

        {:ok, %{request| params: validated_params}}
      else
        :badorigin ->
          {:error, %{message: "bad_origin"}}
        _ ->
          {:error, %{message: "bad_request"}}
      end
    end

    def check_permissions(request, _socket),
      do: {:ok, request}

    def handle_request(request, _socket) do
      network_id = request.params.network_id
      origin_id = request.params.origin
      address = request.params.address

      case ServerPublic.network_browse(network_id, address, origin_id) do
        {:ok, web} ->
          meta = %{web: web}

          {:ok, %{request| meta: meta}}
        error = {:error, %{message: _}} ->
          error
      end
    end

    def reply(request, socket) do
      web = request.meta.web

      [network_id, ip] = web.nip

      type =
        if web.subtype do
          to_string(web.type) <> "_" <> to_string(web.subtype)
        else
          to_string(web.type)
        end

      data = %{
        content: web.content,
        type: type,
        meta: %{
          nip: [to_string(network_id), to_string(ip)],
          password: web.password
        }
      }

      WebsocketUtils.reply_ok(data, socket)
    end
  end
end
