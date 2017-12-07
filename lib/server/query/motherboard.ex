defmodule Helix.Server.Query.Motherboard do

  alias Helix.Server.Model.Component
  alias Helix.Server.Model.Motherboard
  alias Helix.Server.Internal.Motherboard, as: MotherboardInternal

  @spec fetch(Motherboard.id) ::
    Motherboard.t
    | nil
  def fetch(motherboard_id = %Component.ID{}) do
    motherboard_id
    |> MotherboardInternal.fetch()
  end

  @spec get_resources(Motherboard.t) ::
    Motherboard.resources
  @doc """
  Returns the total resources within the given `motherboard`.
  """
  def get_resources(motherboard = %Motherboard{}) do
    motherboard
    |> MotherboardInternal.get_resources()
  end

  defdelegate get_components(motherboard),
    to: MotherboardInternal
  defdelegate get_cpus(motherboard),
    to: MotherboardInternal
  defdelegate get_hdds(motherboard),
    to: MotherboardInternal
  defdelegate get_nics(motherboard),
    to: MotherboardInternal
end
