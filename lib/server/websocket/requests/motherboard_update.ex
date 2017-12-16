import Helix.Websocket.Request

request Helix.Server.Websocket.Requests.MotherboardUpdate do

  import HELL.Macros

  alias HELL.IPv4
  alias HELL.Utils
  alias Helix.Network.Model.Network
  alias Helix.Server.Henforcer.Component, as: ComponentHenforcer
  alias Helix.Server.Henforcer.Server, as: ServerHenforcer
  alias Helix.Server.Model.Component
  alias Helix.Server.Public.Server, as: ServerPublic

  def check_params(request, socket) do
    if request.unsafe["cmd"] == "detach" do
      check_detach(request, socket)
    else
      check_update(request, socket)
    end
  end

  def check_detach(request, socket) do
    with \
      true <- socket.assigns.meta.access == :local || :bad_src
    do
      update_params(request, %{cmd: :detach}, reply: true)
    else
      :bad_src ->
        reply_error(request, "bad_src")

      _ ->
        bad_request(request)
    end
  end

  def check_update(request, socket) do
    with \
      true <- socket.assigns.meta.access == :local || :bad_src,
      {:ok, mobo_id} <- Component.ID.cast(request.unsafe["motherboard_id"]),
      {:ok, slots} <- cast_slots(request.unsafe["slots"]),
      {:ok, ncs} <- cast_ncs(request.unsafe["network_connections"])
    do
      params = %{
        slots: slots,
        network_connections: ncs,
        mobo_id: mobo_id,
        cmd: :update
      }

      update_params(request, params, reply: true)
    else
      :bad_src ->
        reply_error(request, "bad_src")

      :bad_slots ->
        reply_error(request, "bad_slot_data")

      :bad_ncs ->
        reply_error(request, "bad_network_connections")

      _ ->
        bad_request(request)
    end
  end

  def check_permissions(request = %{params: %{cmd: :detach}}, socket) do
    gateway_id = socket.assigns.gateway.server_id

    with \
      {true, relay} <- ComponentHenforcer.can_detach_mobo?(gateway_id)
    do
      meta = %{
        server: relay.server,
        motherboard: relay.motherboard
      }

      update_meta(request, meta, reply: true)
    else
      {false, reason, _} ->
        reply_error(request, reason)
    end

  end

  def check_permissions(request = %{params: %{cmd: :update}}, socket) do
    gateway_id = socket.assigns.gateway.server_id
    entity_id = socket.assigns.gateway.entity_id
    mobo_id = request.params.mobo_id
    slots = request.params.slots
    ncs = request.params.network_connections

    with \
      {true, r0} <- ServerHenforcer.server_exists?(gateway_id),
      {true, r1} <-
        ComponentHenforcer.can_update_mobo?(entity_id, mobo_id, slots, ncs)
    do
      meta = %{
        server: r0.server,
        mobo: r1.mobo,
        components: r1.components,
        owned_components: r1.owned_components,
        network_connections: r1.network_connections,
        entity_network_connections: r1.entity_network_connections
      }

      update_meta(request, meta, reply: true)
    else
      {false, reason, _} ->
        reply_error(request, reason)
    end
  end

  def handle_request(request = %{params: %{cmd: :detach}}, _socket) do
    server = request.meta.server
    motherboard = request.meta.motherboard
    relay = request.relay

    hespawn fn ->
      ServerPublic.detach_mobo(server, motherboard, relay)
    end

    reply_ok(request)
  end

  def handle_request(request = %{params: %{cmd: :update}}, _socket) do
    server = request.meta.server
    mobo = request.meta.mobo
    components = request.meta.components
    ncs = request.meta.network_connections
    entity_ncs = request.meta.entity_network_connections
    relay = request.relay

    # Updates mobo asynchronously
    hespawn fn ->
      ServerPublic.update_mobo(
        server, {mobo, components, ncs}, entity_ncs, relay
      )
    end

    reply_ok(request)
  end

  render_empty()

  defp cast_ncs(nil),
    do: :bad_ncs
  defp cast_ncs(network_connections) do
    try do
      ncs =
        Enum.map(network_connections, fn {nic_id, nc} ->
          {:ok, nic_id} = Component.ID.cast(nic_id)
          {:ok, ip} = IPv4.cast(nc["ip"])
          {:ok, network_id} = Network.ID.cast(nc["network_id"])

          {nic_id, {network_id, ip}}
        end)

      {:ok, ncs}
    rescue
      _ ->
        :bad_ncs
    end
  end

  defp cast_slots(nil),
    do: :bad_slots
  defp cast_slots(slots) do
    try do
      slots =
        slots
        |> Enum.map(fn {slot_id, component_id} ->
          component_id =
            if component_id do
              Component.ID.cast!(component_id)
            else
              nil
            end

          {:ok, slot_id} = cast_slot_id(slot_id)

          {slot_id, component_id}
        end)
        |> Enum.into(%{})

      {:ok, slots}
    rescue
      _ ->
        :bad_slots
    end
  end

  defp cast_slot_id("cpu_" <> id),
    do: concat_slot(:cpu, id)
  defp cast_slot_id("ram_" <> id),
    do: concat_slot(:ram, id)
  defp cast_slot_id("hdd_" <> id),
    do: concat_slot(:hdd, id)
  defp cast_slot_id("nic_" <> id),
    do: concat_slot(:nic, id)
  defp cast_slot_id("usb_" <> id),
    do: concat_slot(:usb, id)
  defp cast_slot_id(_),
    do: :error

  defp concat_slot(component, id) do
    case Integer.parse(id) do
      {_, ""} ->
        slot_id =
          component
          |> Utils.concat_atom("_")
          |> Utils.concat_atom(id)

        {:ok, slot_id}

      _ ->
        :error
    end
  end
end
