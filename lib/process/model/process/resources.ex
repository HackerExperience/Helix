import Helix.Process.Resources

resources Helix.Process.Model.Process.Resources do
  @moduledoc """
  This is where we define all resources that may be used by a process.

  It's also where we define how each resource should *behave*.
  """

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
