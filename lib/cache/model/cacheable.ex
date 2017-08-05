alias Helix.Cache.Model.ComponentCache
alias Helix.Cache.Model.NetworkCache
alias Helix.Cache.Model.ServerCache
alias Helix.Cache.Model.StorageCache

defprotocol Helix.Cache.Model.Cacheable do

  def format_input(data)

  def format_output(data)

end

defimpl Helix.Cache.Model.Cacheable, for: ServerCache do

  alias Helix.Entity.Model.Entity
  alias Helix.Hardware.Model.Component
  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Storage
  alias Helix.Cache.Model.Cacheable.Utils
  alias Helix.Cache.Model.ServerCache

  def format_input(row) do
    networks = if row.networks do
      Enum.map(row.networks, fn(net) ->
        %{network_id: to_string(net.network_id), ip: net.ip}
      end)
    else
      nil
    end

    %{row | networks: networks}
    |> ServerCache.create_changeset()
    |> Ecto.Changeset.apply_changes()
  end

  def format_output(row) do
    storages = if row.storages do
      Enum.map(row.storages, fn(storage) ->
        Utils.cast(Storage.ID, storage)
      end)
    else
      nil
    end

    components = if row.components do
      Enum.map(row.components, fn(component) ->
        Utils.cast(Component.ID, component)
      end)
    else
      nil
    end

    networks = if row.networks do
      Enum.map(row.networks, fn(net) ->
        {network_id, ip} =
          if Map.has_key?(net, "network_id") do
            {net["network_id"], net["ip"]}
          else
            {net.network_id, net.ip}
          end
        %{network_id: Utils.cast(Network.ID, network_id), ip: ip}
      end)
    else
      nil
    end

    %{
      server_id: Utils.cast(Server.ID, row.server_id),
      entity_id: Utils.cast(Entity.ID, row.entity_id),
      motherboard_id: Utils.cast(Component.ID, row.motherboard_id),
      networks: networks,
      storages: storages,
      resources: cast_resources(row.resources),
      components: components
    }
  end

  defp cast_resources(resources) do
    if resources do
      %{
        cpu: resources["cpu"],
        ram: resources["ram"],
        hdd: resources["hdd"],
        net: resources["net"]
      }
    end
  end
end

defimpl Helix.Cache.Model.Cacheable, for: StorageCache do

  alias Helix.Server.Model.Server
  alias Helix.Software.Model.Storage
  alias Helix.Cache.Model.Cacheable.Utils
  alias Helix.Cache.Model.StorageCache

  def format_input(row) do
    StorageCache.create_changeset(row)
    |> Ecto.Changeset.apply_changes()
  end

  def format_output(row) do
    %{
      storage_id: Utils.cast(Storage.ID, row.storage_id),
      server_id: Utils.cast(Server.ID, row.server_id)
    }
  end
end

defimpl Helix.Cache.Model.Cacheable, for: NetworkCache do

  alias Helix.Network.Model.Network
  alias Helix.Server.Model.Server
  alias Helix.Cache.Model.Cacheable.Utils
  alias Helix.Cache.Model.NetworkCache

  def format_input(row) do
    row
    |> NetworkCache.create_changeset()
    |> Ecto.Changeset.apply_changes()
  end

  def format_output(row) do
    %{
      network_id: Utils.cast(Network.ID, row.network_id),
      ip: row.ip,
      server_id: Utils.cast(Server.ID, row.server_id)
    }
  end
end

defimpl Helix.Cache.Model.Cacheable, for: ComponentCache do

  alias Helix.Hardware.Model.Component
  alias Helix.Cache.Model.ComponentCache
  alias Helix.Cache.Model.Cacheable.Utils

  def format_input(row) do
    row
    |> ComponentCache.create_changeset()
    |> Ecto.Changeset.apply_changes()
  end

  def format_output(row) do
    %{
      component_id: Utils.cast(Component.ID, row.component_id),
      motherboard_id: Utils.cast(Component.ID, row.motherboard_id)
    }
  end
end

defmodule Helix.Cache.Model.Cacheable.Utils do
  def cast(id, value) do
    case apply(id, :cast, [value]) do
      {:ok, id} ->
        id
      :error ->
        nil
    end
  end
end

###########################################
# IGNORE THE FOLLOWING LINES.
# Dialyzer is not particularly a fan of protocols, so it will emit a lot of
# "unknown functions" for non-implemented types on a protocol. This hack will
# implement any possible type to avoid those warnings (albeit it might increase
# the compilation time in a second)
###########################################

impls = [
  Atom,
  BitString,
  Float,
  Function,
  Integer,
  List,
  Map,
  PID,
  Port,
  Reference,
  Tuple
]

for impl <- impls do
  defimpl Helix.Cache.Model.Cacheable, for: impl do
    def format_input(input),
      do: raise "#{inspect input} is not a valid value for Cacheable"

    def format_output(input),
      do: raise "#{inspect input} is not a valid value for Cacheable"
  end
end
