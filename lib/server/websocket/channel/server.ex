defmodule Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  Channel to notify all players connected to a certain server about events
  regarding said server
  """

  use Phoenix.Channel

  alias Helix.Network.Service.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Server.Service.Henforcer.Server, as: Henforcer

  intercept ["notification"]

  @doc false
  def join(topic, message, socket)

  # Connecting to an external server
  def join("server:" <> server_id, %{"gateway_id" => gateway}, socket) do
    has_connection? = fn ->
      NetworkHenforcer.has_ssh_connection?(gateway, server_id)
    end

    with \
      true <- Henforcer.server_exists?(server_id) || {:error, :not_found},
      true <- Henforcer.server_exists?(gateway) || {:error, :not_found},
      owner = EntityAPI.fetch_server_owner(gateway),
      account_id = EntityAPI.get_entity_id(socket.assigns.account),
      owner_id = EntityAPI.get_entity_id(owner),
      true <- owner_id == account_id || {:error, :not_owner},
      true <- has_connection?.() || {:error, :not_connected}
    do
      # PHEW! That means that the server exists, the player owns the specified
      # gateway and that it has an SSH connection to the target server
      {:ok, socket}
    else
      {:error, :not_found} ->
        {:error, %{reason: "invalid server"}}
      {:error, :not_owner} ->
        {:error, %{reason: "player is not the server owner"}}
      {:error, :not_connected} ->
        {:error, %{reason: "gateway is not connected to target server"}}
    end
  end

  # Connecting to player's own gateways
  def join("server:" <> server_id, _, socket) do
    with \
      true <- Henforcer.server_exists?(server_id) || {:error, :not_found},
      owner = EntityAPI.fetch_server_owner(server_id),
      account = socket.assigns.account,
      owner_id = EntityAPI.get_entity_id(owner),
      account_id = EntityAPI.get_entity_id(account),
      true <- owner_id == account_id || {:error, :not_owner}
    do
      {:ok, socket}
    else
      {:error, :not_found} ->
        {:error, %{reason: "invalid server"}}
      {:error, :not_owner} ->
        {:error, %{reason: "player is not the server owner"}}
    end
  end

  @doc false
  # We'll use this function in the future to filter and transform notification
  # events
  def handle_out("notification", notification, socket) do
    push socket, "notification", notification

    {:noreply, socket}
  end

  def notify(server_id, notification) do
    Helix.Endpoint.broadcast(
      "server:" <> server_id,
      "notification",
      notification)
  end
end
