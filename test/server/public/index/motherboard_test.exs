defmodule Helix.Server.Public.Index.MotherboardTest do

  use Helix.Test.Case.Integration

  alias Helix.Server.Public.Index.Motherboard, as: MotherboardIndex
  alias Helix.Server.Query.Motherboard, as: MotherboardQuery
  alias Helix.Server.Query.Server, as: ServerQuery

  alias Helix.Test.Network.Helper, as: NetworkHelper
  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup

  @internet_id NetworkHelper.internet_id()
  @internet_id_str to_string(@internet_id)

  describe "index/1" do
    test "indexes empty motherboard" do
      {server, _} = ServerSetup.server()

      # Remove mobo
      ServerHelper.update_server_mobo(server, nil)

      # Look mah, no mobo
      server = ServerQuery.fetch(server.server_id)
      refute server.motherboard_id

      index = MotherboardIndex.index(server)

      refute index.motherboard_id
      assert Enum.empty?(index.network_connections)
    end

    test "indexes motherboard" do
      {server, _} = ServerSetup.server()

      index = MotherboardIndex.index(server)

      assert index.motherboard == MotherboardQuery.fetch(server.motherboard_id)
      assert [nc] = index.network_connections

      assert nc.network_id == @internet_id
      assert nc.ip == ServerHelper.get_ip(server)
      assert nc.nic_id == index.motherboard.slots.nic_1.component_id
    end
  end

  describe "render_index/1" do
    test "renders empty motherboard" do
      {server, _} = ServerSetup.server()

      # Remove mobo
      ServerHelper.update_server_mobo(server, nil)

      # Look mah, no mobo
      server = ServerQuery.fetch(server.server_id)
      refute server.motherboard_id

      rendered =
        server
        |> MotherboardIndex.index()
        |> MotherboardIndex.render_index()

      refute rendered.motherboard_id
      assert Enum.empty?(rendered.network_connections)
      assert Enum.empty?(rendered.slots)
    end

    test "renders the motherboard index" do
      {server, _} = ServerSetup.server()

      ServerHelper.update_server_mobo(server, :mobo_999)

      motherboard = MotherboardQuery.fetch(server.motherboard_id)

      [cpu] = MotherboardQuery.get_cpus(motherboard)
      [hdd] = MotherboardQuery.get_hdds(motherboard)
      [ram] = MotherboardQuery.get_rams(motherboard)
      [nic] = MotherboardQuery.get_nics(motherboard)

      ip = ServerHelper.get_ip(server)

      rendered =
        server
        |> MotherboardIndex.index()
        |> MotherboardIndex.render_index()

      assert rendered.motherboard_id == to_string(server.motherboard_id)

      # NC data is valid
      assert ncs = rendered.network_connections
      assert Map.has_key?(ncs, to_string(nic.component_id))

      assert %{
        network_id: @internet_id_str,
        ip: ip
      } == ncs[to_string(nic.component_id)]

      # Slot data is valid
      slots = rendered.slots

      assert rendered.slots["cpu_1"].component_id == to_string(cpu.component_id)
      assert rendered.slots["cpu_1"].type == "cpu"
      assert rendered.slots["hdd_1"].component_id == to_string(hdd.component_id)
      assert rendered.slots["hdd_1"].type == "hdd"
      assert rendered.slots["ram_1"].component_id == to_string(ram.component_id)
      assert rendered.slots["ram_1"].type == "ram"
      assert rendered.slots["nic_1"].component_id == to_string(nic.component_id)
      assert rendered.slots["nic_1"].type == "nic"

      # Returned all slots (available and free slots)
      assert map_size(slots) > 10

      # Available slots have an empty `component_id`
      refute rendered.slots["cpu_2"].component_id
      refute rendered.slots["ram_2"].component_id
      refute rendered.slots["hdd_2"].component_id
      refute rendered.slots["nic_2"].component_id
    end
  end
end
