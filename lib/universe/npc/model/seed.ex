defmodule Helix.Universe.NPC.Model.Seed do

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
      %{spec: "todo", custom: %{region: "1b"}}
    ],
    "Bank2" => [
      %{spec: "todo", custom: %{region: "2a"}},
      %{spec: "todo", custom: %{region: "2b"}}
    ]
  }

  @ids %{
    "DC0" => %{
      npc: "2::920e:c06c:abea:b249:a158",
      servers: ["10::15c1:d147:47f9:b4b2:cbbd"]
    },
    "Bank1" => %{
      npc: "2::920e:c06c:abea:b249:a159",
      servers: [
        "10::15c1:d147:47f9:b4b2:cbbe",
        "10::15c1:d147:47f9:b4b2:cbbf",
      ]
    },
    "Bank2" => %{
      npc: "2::920e:c06c:abea:b249:a160",
      servers: [
        "10::15c1:d147:47f9:b4b2:cbc0",
        "10::15c1:d147:47f9:b4b2:cbc1",
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
    Map.get(@ids, key)
    |> Access.get(:npc)
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
      id: ids.npc,
      type: type,
      servers: server_entries,
      anycast: Map.get(@dns, key, false),
      custom: Map.get(@custom, key, false)
    }
  end

  defp server_entry({server, id}) do
    %{id: id,
      spec: server.spec,
      static_ip: Map.get(server, :ip, false),
      custom: Map.get(server, :custom, false)
    }
  end

  defp stop,
    do: raise "Your seed config is invalid"
end
