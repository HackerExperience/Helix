defmodule Helix.Account.Public.Account do

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Public.Index, as: ServerIndex
  alias Helix.Story.Public.Index, as: StoryIndex
  alias Helix.Account.Public.Index, as: AccountIndex

  @type bootstrap ::
    %{
      account: AccountIndex.index,
      servers: ServerIndex.index,
      storyline: StoryIndex.index
    }

  @type rendered_bootstrap ::
    %{
      account: AccountIndex.rendered_index,
      servers: ServerIndex.rendered_index,
      storyline: StoryIndex.rendered_index
    }

  @doc """
  Returns all data related to the player. Used by the client upon login (or sync
  request).

  The final result is a fractal-like format created by the indexes being used.
  """
  @spec bootstrap(Entity.id) ::
    bootstrap
  def bootstrap(entity_id) do
    entity = EntityQuery.fetch(entity_id)

    %{
      account: AccountIndex.index(entity),
      servers: ServerIndex.index(entity),
      storyline: StoryIndex.index(entity_id)
    }
  end

  @doc """
  Renders the bootstrap result by calling each index renderer.

  Similar in purpose to `ProcessViewable`.
  """
  @spec render_bootstrap(bootstrap) ::
    rendered_bootstrap
  def render_bootstrap(bootstrap) do
    %{
      account: AccountIndex.render_index(bootstrap.account),
      servers: ServerIndex.render_index(bootstrap.servers),
      storyline: StoryIndex.render_index(bootstrap.storyline)
    }
  end
end
