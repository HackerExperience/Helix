defmodule Helix.Process.Model.Process.Resources.Utils do

  alias Helix.Network.Model.Network

  def format_network(key = %Network.ID{}, value),
    do: {key, value}
  def format_network(key, value),
    do: {Network.ID.cast!(key), value}
end

import Helix.Process.Resources

resources Helix.Process.Model.Process.Resources do

  alias Helix.Process.Resources.Behaviour
  alias Helix.Process.Model.Process.Resources.Utils, as: ResourcesUtils

  resource RAM,
    behaviour: Behaviour.Default

  resource CPU,
    behaviour: Behaviour.Default

  resource DLK,
    behaviour: Behaviour.KV,
    key: :network_id,
    formatter: &ResourcesUtils.format_network/2

  resource ULK,
    behaviour: Behaviour.KV,
    key: :network_id,
    formatter: &ResourcesUtils.format_network/2
end
