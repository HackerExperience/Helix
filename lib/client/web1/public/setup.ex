defmodule Helix.Client.Web1.Public.Setup do

  alias Helix.Client.Web1.Action.Setup, as: SetupAction

  defdelegate add_pages(entity_id, pages),
    to: SetupAction
end
