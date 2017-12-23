defmodule Helix.Server.Action.Motherboard do

  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal

  @type motherboard_data :: __MODULE__.Update.motherboard_data
  @type update_component :: __MODULE__.Update.update_component
  @type update_nc :: __MODULE__.Update.update_nc

  defdelegate setup(mobo, initial_components),
    to: MotherboardInternal

  defdelegate link(motherboard, mobo_component, link_component, slot_id),
    to: MotherboardInternal
  defdelegate link(motherboard, link_component, slot_id),
    to: MotherboardInternal

  defdelegate unlink(component),
    to: MotherboardInternal

  defdelegate update(cur_mobo_data, new_mobo_data, entity_ncs),
    to: __MODULE__.Update

  defdelegate detach(motherboard),
    to: __MODULE__.Update
end
