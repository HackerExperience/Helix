defmodule Helix.Server.Action.Motherboard do

  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal

  defdelegate setup(mobo, initial_components),
    to: MotherboardInternal

  defdelegate unlink(motherboard, component),
    to: MotherboardInternal
end
