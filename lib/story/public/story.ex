defmodule Helix.Story.Public.Story do

  alias Helix.Story.Action.Flow.Story, as: StoryFlow

  @doc """
  Sends a reply from the given entity to the assigned contact
  """
  defdelegate send_reply(entity_id, contact_id, reply_id),
    to: StoryFlow
end
