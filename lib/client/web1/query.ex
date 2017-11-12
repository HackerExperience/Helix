defmodule Helix.Client.Web1.Query do

  alias Helix.Client.Web1.Internal, as: Web1Internal

  @doc """
  Fetches the setup information for `entity_id`
  """
  defdelegate fetch_setup(entity_id),
    to: Web1Internal

  @doc """
  Returns a list of all setup pages that `entity_id` has already interacted with
  """
  defdelegate get_setup_pages(entity_id),
    to: Web1Internal
end
