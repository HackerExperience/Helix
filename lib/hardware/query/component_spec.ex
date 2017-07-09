defmodule Helix.Hardware.Query.ComponentSpec do

  alias Helix.Hardware.Internal.ComponentSpec, as: ComponentSpecInternal
  alias Helix.Hardware.Model.ComponentSpec

  @spec fetch(String.t) :: ComponentSpec.t | nil
  @doc """
  Fetches acomponent specification
  """
  def fetch(spec_id) do
    ComponentSpecInternal.fetch(spec_id)
  end

  @spec find([ComponentSpecInternal.find_param], meta :: []) ::
    [ComponentSpec.t]
  @doc """
  Search for component specifications

  ## Params

    * `:type` - filters by specification type
  """
  def find(params, meta \\ []) do
    ComponentSpecInternal.find(params, meta)
  end

end
