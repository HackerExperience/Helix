defmodule Helix.Client.Web1.Query do

  alias Helix.Client.Web1.Internal, as: Web1Internal

  def get_setup_pages(entity_id) do
    Web1Internal.get_setup_pages(entity_id)
  end
end
