defmodule Helix.Account.Public.Index do

  alias Helix.Client.Renderer, as: ClientRenderer
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Network.Model.Bounce
  alias Helix.Network.Query.Bounce, as: BounceQuery
  alias Helix.Server.Model.Server
  alias Helix.Account.Public.Index.Inventory, as: InventoryIndex

  @type index ::
    %{
      mainframe: Server.id,
      inventory: InventoryIndex.index,
      bounces: [Bounce.t]
    }

  @type rendered_index ::
    %{
      mainframe: String.t,
      inventory: InventoryIndex.rendered_index,
      bounces: [ClientRenderer.rendered_bounce]
    }

  @spec index(Entity.t) ::
    index
  def index(entity) do
    mainframe =
      entity
      |> EntityQuery.get_servers()
      |> Enum.reverse()
      |> List.first()

    bounces = BounceQuery.get_by_entity(entity)

    %{
      mainframe: mainframe,
      inventory: InventoryIndex.index(entity),
      bounces: bounces
    }
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    %{
      mainframe: to_string(index.mainframe),
      inventory: InventoryIndex.render_index(index.inventory),
      bounces: Enum.map(index.bounces, &ClientRenderer.render_bounce/1)
    }
  end
end
