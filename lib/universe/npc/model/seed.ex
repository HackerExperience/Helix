defmodule Helix.Universe.NPC.Model.Seed do

  alias Helix.Server.Model.Server
  alias Helix.Universe.NPC.Model.NPC

  @source [
    %{key: "DC0", type: :download_center},
    %{key: "Bank1", type: :bank},
    %{key: "Bank2", type: :bank}
  ]

  @dns %{
    "DC0" => "dc.com",
    "Bank1" => "bank.com",
    "Bank2" => "bank2.com"
  }

  @servers %{
    "DC0" => [%{spec: "todo", ip: "1.2.3.4"}],
    "Bank1" => [
      %{spec: "todo", custom: %{region: "1a"}},
      %{spec: "todo", custom: %{region: "1b"}},
      %{spec: "todo", custom: %{region: "1c"}}
    ],
    "Bank2" => [
      %{spec: "todo", custom: %{region: "2a"}},
      %{spec: "todo", custom: %{region: "2b"}}
    ]
  }

  @ids %{
    "DC0" => %{
      npc: "ffff:000e:af12:a800:184b:3116:3b09:d61a",
      servers: ["ffe0:f12:a827:5800:1868:d1d3:912:6825"]
    },
    "Bank1" => %{
      npc: "ffff:100e:af12:a800:184b:3116:3b09:d61a",
      servers: [
        "ffe2:f12:a827:5800:1870:38a5:2462:3925",
        "ffe2:f12:a827:5800:1871:ebec:5461:de25",
        "ffe2:f12:a827:5800:1872:7abd:b7b1:a725"
      ]
    },
    "Bank2" => %{
      npc: "ffff:200e:af12:a800:184b:3116:3b09:d61a",
      servers: [
        "ffe4:f12:a827:5800:1875:3388:ab69:7425",
        "ffe4:f12:a827:5800:1875:ed3e:5406:7925",
      ]
    }
  }

  @custom %{
    "Bank1" => %{name: "Bank One"},
    "Bank2" => %{name: "Bank Two"}
  }

  def search_by_type(type) do
    key =
      case type do
        :download_center ->
          "DC0"
        :bank ->
          "Bank1"
      end

    generate_entry(key, type)
  end

  def get_npc_id(key) do
    npc_id =
      @ids
      |> Map.get(key)
      |> Access.get(:npc)

    if npc_id do
      NPC.ID.cast!(npc_id)
    end
  end

  def seed do
    # TODO: Cache and verify for changes based on hash or something like that.
    generate_seed()
  end

  defp generate_seed do
    Enum.map(@source, fn(npc) ->
      generate_entry(npc.key, npc.type)
    end)
  end

  defp generate_entry(key, type) do
    ids = Map.get(@ids, key)

    servers = Map.get(@servers, key)

    Kernel.length(servers) == Kernel.length(ids.servers) || stop()

    zip = Enum.zip(servers, ids.servers)
    server_entries = Enum.map(zip, fn(server) ->
      server_entry(server)
    end)

    %{
      id: NPC.ID.cast!(ids.npc),
      type: type,
      servers: server_entries,
      anycast: Map.get(@dns, key, false),
      custom: Map.get(@custom, key, false)
    }
  end

  defp server_entry({server, id}) do
    %{id: Server.ID.cast!(id),
      spec: server.spec,
      static_ip: Map.get(server, :ip, false),
      custom: Map.get(server, :custom, false)
    }
  end

  defp stop,
    do: raise "Your seed config is invalid"
end
