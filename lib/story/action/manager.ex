defmodule Helix.Story.Action.Manager do

  alias Helix.Story.Internal.Manager, as: ManagerInternal

  @doc """
  Creates an entry on the Story.Manager with the corresponding server, network
  and any other information linked to the entity storyline.
  """
  defdelegate setup(entity, server, network),
    to: ManagerInternal

  @doc """
  Removes the given Story.Manager entry.
  """
  defdelegate remove(manager),
    to: ManagerInternal
end
