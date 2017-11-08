defmodule Helix.Process.Model.Process.Resources.Utils do

  alias Helix.Network.Model.Network

  @spec format_network(Network.idtb, term) ::
    {Network.id, term}
  def format_network(key = %Network.ID{}, value),
    do: {key, value}
  def format_network(key, value),
    do: {Network.ID.cast!(key), value}
end

import Helix.Process.Resources

resources Helix.Process.Model.Process.Resources do

  alias Helix.Network.Model.Network
  alias Helix.Process.Model.Process.Resources.Utils, as: ResourcesUtils
  alias Helix.Process.Resources.Behaviour

  @type t ::
    %{
      ram: number,
      cpu: number,
      dlk: %{Network.id => number},
      ulk: %{Network.id => number}
    }

  @type map_t(type) ::
    %{
      ram: type,
      cpu: type,
      dlk: %{Network.id => type},
      ulk: %{Network.id => type}
    }

  resource RAM,
    behaviour: Behaviour.Default

  resource CPU,
    behaviour: Behaviour.Default

  resource DLK,
    behaviour: Behaviour.KV,
    key: :network_id,
    formatter: &ResourcesUtils.format_network/2,
    mirror: :ulk

  resource ULK,
    behaviour: Behaviour.KV,
    key: :network_id,
    formatter: &ResourcesUtils.format_network/2,
    mirror: :dlk
end
