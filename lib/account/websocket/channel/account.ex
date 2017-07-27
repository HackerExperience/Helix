defmodule Helix.Account.Websocket.Channel.Account do
  @moduledoc """
  Channel to notify an user of an action that affects them.
  """

  use Phoenix.Channel

  alias Helix.Hardware.Query.Component, as: ComponentQuery
  alias Helix.Hardware.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Entity.Query.Database, as: DatabaseQuery
  alias Helix.Entity.Query.Entity, as: EntityQuery

  def join("account:" <> account_id, _message, socket) do
    # TODO: Provide a cleaner way to check this

    player_account_id = to_string(socket.assigns.account.account_id)
    if account_id == player_account_id do
      {:ok, socket}
    else
      {:error, %{reason: "can't join another user's notification channel"}}
    end
  end

  def handle_in("database.index", _message, socket) do
    database =
      socket.assigns.account.account_id
      |> EntityQuery.get_entity_id()
      |> EntityQuery.fetch()
      |> DatabaseQuery.get_database()

    {:reply, {:ok, %{data: %{entries: database}}}, socket}
  end

  # TODO: Fetch server's IPs
  def handle_in("server.index", _message, socket) do
    servers =
      socket.assigns.account
      |> EntityQuery.get_entity_id()
      |> EntityQuery.fetch()
      |> EntityQuery.get_servers()
      |> Enum.map(&ServerQuery.fetch/1)
      |> Enum.map(fn
        server = %{motherboard_id: motherboard} when not is_nil(motherboard) ->
          motherboard =
            server.motherboard_id
            |> ComponentQuery.fetch()
            |> MotherboardQuery.fetch()
            |> MotherboardQuery.preload_components()

          {server, motherboard}
        server ->
          {server, nil}
      end)
      |> Enum.map(&render_server/1)

    {:reply, {:ok, %{data: %{servers: servers}}}, socket}
  end

  # TODO: Move this to a viewer
  def render_server({server, nil}) do
    %{
      server_id: server.server_id,
      server_type: server.server_type,
      password: server.password,
      hardware: nil,
      ips: []
    }
  end
  def render_server({server, motherboard}) do
    %{
      server_id: server.server_id,
      server_type: server.server_type,
      password: server.password,
      hardware: %{
        # FIXME: This is querying the db again for the components
        resources: MotherboardQuery.resources(motherboard),
        components: render_components(motherboard)
      },
      ips: []
    }
  end

  defp render_components(%{slots: slots}) do
    slots
    |> Enum.map(fn slot = %{component: component = %{}} ->
      internal_id = slot.slot_internal_id

      data = %{
        component_id: component.component_id,
        component_type: component.component_type,
        # TODO: Return data about component specialization
        meta: %{}
      }

      {internal_id, data}
    end)
    |> :maps.from_list()
  end

  def notify(account_id, notification) do
    Helix.Endpoint.broadcast(
      "account:" <> account_id,
      "notification",
      notification)
  end
end
