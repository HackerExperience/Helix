defmodule Helix.Server.Query.Motherboard do

  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal

  def fetch(motherboard_id = %Component.ID{}) do
    motherboard_id
    |> MotherboardInternal.fetch()
  end

  def get_resources(motherboard = %Motherboard{}) do
    motherboard
    |> MotherboardInternal.get_resources()
  end
end
