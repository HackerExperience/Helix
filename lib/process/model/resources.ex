import Helix.Process.Resources

resources Helix.Process.Model.Process.Resources do

  alias Helix.Process.Resources.Behaviour

  resource RAM,
    behaviour: Behaviour.Default

  resource CPU,
    behaviour: Behaviour.Default

  resource DLK,
    behaviour: Behaviour.KV,
    key: :network_id

  resource ULK,
    behaviour: Behaviour.KV,
    key: :network_id
end
