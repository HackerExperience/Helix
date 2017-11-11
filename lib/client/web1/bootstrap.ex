defmodule Helix.Client.Web1.Public do

  alias Helix.Client.Web1.Query, as: Web1Query

  def bootstrap(entity_id) do
    %{
      setup: %{
        pages: Web1Query.get_setup_pages(entity_id)
      }
    }
  end
end
