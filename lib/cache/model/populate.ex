defmodule Helix.Cache.Model.Populate do
  defmodule Server do
    @type t :: %__MODULE__{}

    defstruct [:server_id, :entity_id, :motherboard_id, :networks, :storages,
               :resources, :components]

    def new(sid, eid) do
      %__MODULE__{
        server_id: sid,
        entity_id: eid,
        motherboard_id: nil
      }
    end
    def new({sid, eid, mid, networks, storages, resources, components}) do
      %__MODULE__{
        server_id: sid,
        entity_id: eid,
        motherboard_id: mid,
        networks: networks,
        storages: storages,
        resources: resources,
        components: components
      }
    end
  end

  defmodule Storage do
    @type t :: %__MODULE__{}

    defstruct [:storage_id, :server_id]

    def new(storage_id, server_id) do
      %__MODULE__{
        storage_id: storage_id,
        server_id: server_id
      }
    end
  end

  defmodule Component do
    @type t :: %__MODULE__{}

    defstruct [:component_id, :motherboard_id]

    def new(component_id, motherboard_id) do
      %__MODULE__{
        component_id: component_id,
        motherboard_id: motherboard_id
      }
    end
  end

  defmodule Network do
    @type t :: %__MODULE__{}

    defstruct [:network_id, :ip, :server_id]

    def new(network_id, ip, server_id) do
      %__MODULE__{
        network_id: network_id,
        ip: ip,
        server_id: server_id
      }
    end
  end
end
