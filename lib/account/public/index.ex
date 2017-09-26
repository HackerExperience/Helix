defmodule Helix.Account.Public.Index do

  alias Helix.Entity.Model.Entity
  alias Helix.Story.Public.Index, as: StoryIndex

  @type index :: %{
    storyline: StoryIndex.index
  }

  @type rendered_index :: %{
    storyline: StoryIndex.rendered_index
  }

  @spec index(Entity.id) ::
    index
  def index(entity_id) do
    %{
      storyline: StoryIndex.index(entity_id)
    }
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    %{
      storyline: StoryIndex.render_index(index.storyline)
    }
  end
end
