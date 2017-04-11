defmodule Helix.Server.Websocket.Channel.Server do
  @moduledoc """
  Channel to notify all players connected to a certain server about events
  regarding said server
  """

  use Phoenix.Channel

  alias Helix.Network.Service.Henforcer.Network, as: NetworkHenforcer
  alias Helix.Entity.Service.API.Entity, as: EntityAPI
  alias Helix.Software.Controller.Storage, as: StorageController
  alias Helix.Hardware.Service.API.Component, as: ComponentAPI
  alias Helix.Hardware.Service.API.Motherboard, as: MotherboardAPI
  alias Helix.Software.Service.API.File, as: FileAPI
  alias Helix.Server.Service.API.Server, as: ServerAPI
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
      true <- Henforcer.functioning?(server_id) || {:error, :not_assembled},
      true <- Henforcer.functioning?(gateway) || {:error, :not_assembled},
      owner = EntityAPI.fetch_server_owner(gateway),
      account_id = EntityAPI.get_entity_id(socket.assigns.account),
      owner_id = EntityAPI.get_entity_id(owner),
      true <- owner_id == account_id || {:error, :not_owner},
      true <- has_connection?.() || {:error, :not_connected}
    do
      # PHEW! That means that the server exists, the player owns the specified
      # gateway and that it has an SSH connection to the target server

      socket = assign(
        socket,
        :servers,
        %{gateway: gateway, destination: server_id})

      {:ok, socket}
    else
      {:error, :not_found} ->
        {:error, %{reason: "invalid server"}}
      {:error, :not_assembled} ->
        {:error, %{reason: "server is not assembled"}}
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
      true <- Henforcer.functioning?(server_id) || {:error, :not_assembled},
      owner = EntityAPI.fetch_server_owner(server_id),
      account = socket.assigns.account,
      owner_id = EntityAPI.get_entity_id(owner),
      account_id = EntityAPI.get_entity_id(account),
      true <- owner_id == account_id || {:error, :not_owner}
    do
      socket = assign(
        socket,
        :servers,
        %{gateway: server_id, destination: server_id})

      {:ok, socket}
    else
      {:error, :not_found} ->
        {:error, %{reason: "invalid server"}}
      {:error, :not_assembled} ->
        {:error, %{reason: "server is not assembled"}}
      {:error, :not_owner} ->
        {:error, %{reason: "player is not the server owner"}}
    end
  end

  @doc false
  def handle_in("get_files", _, socket) do
    server = ServerAPI.fetch(socket.assigns.servers.destination)
    hdds =
      server.motherboard_id
      |> ComponentAPI.fetch()
      |> MotherboardAPI.fetch!()
      |> MotherboardAPI.get_slots()
      # TODO: Delegate this to a function on Motherboard API
      # Gets hdds linked to the motherboard
      |> Enum.filter_map(
        &(&1.link_component_type == :hdd && &1.link_component_id),
        &(&1.link_component_id))

    files =
      hdds
      # FIXME: This belongs to an API function that facades this boring shit
      |> Enum.map(&StorageController.get_storage_from_hdd/1)
      |> Enum.uniq()
      |> Enum.reject(&is_nil/1)
      # Returns a map %{path => [files]}
      |> Enum.map(&FileAPI.storage_contents/1)
      |> Enum.reduce(%{}, fn el, acc ->
        # Merge the maps, so %{"foo" => [1]} and %{"foo" => [2]} becomes
        # %{"foo" => [1, 2]}
        Map.merge(acc, el, fn _k, v1, v2 -> v1 ++ v2 end)
      end)
      # HACK: FIXME: This belongs to a viewable protocol. We're doing it as it
      #   is now so it works before we do the real work (?)
      |> Enum.map(fn {path, files} ->
        files = for file <- files do
          Map.take(
            file,
            [
              :file_id,
              :name,
              :path,
              :full_path,
              :file_size,
              :software_type,
              :inserted_at,
              :updated_at])
        end

        {path, files}
      end)
      |> :maps.from_list()

    {:reply, {:ok, files}, socket}
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
