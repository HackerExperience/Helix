defmodule Helix.Story.Query.Manager do

  alias Helix.Story.Internal.Manager, as: ManagerInternal

  defdelegate fetch(entity_id),
    to: ManagerInternal
end
