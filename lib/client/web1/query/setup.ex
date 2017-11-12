defmodule Helix.Client.Web1.Query.Setup do

  alias Helix.Client.Web1.Internal.Setup, as: SetupInternal

  @doc """
  Fetches the setup information for `entity_id`
  """
  defdelegate fetch(entity_id),
    to: SetupInternal

  @doc """
  Returns a list of all setup pages that `entity_id` has already interacted with
  """
  defdelegate get_pages(entity_id),
    to: SetupInternal
end
