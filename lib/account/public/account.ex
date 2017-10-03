defmodule Helix.Account.Public.Account do

  alias Helix.Entity.Model.Entity
  alias Helix.Server.Public.Index, as: ServerIndex
  alias Helix.Account.Public.Index, as: AccountIndex

  @type bootstrap ::
    %{
      account: AccountIndex.index,
      servers: ServerIndex.index
    }

  @doc """
  Returns all data related to the player. Used by the client upon login (or sync
  request).

  The final result is a fractal-like format created by the indexes being used.
  """
  @spec bootstrap(Entity.id) ::
    bootstrap
  def bootstrap(entity_id) do
    %{
      account: AccountIndex.index(entity_id),
      servers: ServerIndex.index(entity_id)
    }
  end

  @doc """
  Renders the bootstrap result by calling each index renderer.

  Similar in purpose to `ProcessViewable`.
  """
  @spec render_bootstrap(bootstrap) ::
    %{
      account: AccountIndex.rendered_index,
      servers: ServerIndex.rendered_index
    }
  def render_bootstrap(bootstrap) do
    %{
      account: AccountIndex.render_index(bootstrap.account),
      servers: ServerIndex.render_index(bootstrap.servers),
    }
  end
end
