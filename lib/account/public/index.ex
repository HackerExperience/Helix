defmodule Helix.Account.Public.Index do

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Account.Public.Index.Inventory, as: InventoryIndex

  @type index ::
    %{
      mainframe: Server.id,
      inventory: InventoryIndex.index
    }

  @type rendered_index ::
    %{
      mainframe: String.t,
      inventory: InventoryIndex.rendered_index
    }

  @spec index(Entity.t) ::
    index
  def index(entity) do
    mainframe =
      entity
      |> EntityQuery.get_servers()
      |> Enum.reverse()
      |> List.first()

    %{
      mainframe: mainframe,
      inventory: InventoryIndex.index(entity)
    }
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    %{
      mainframe: to_string(index.mainframe),
      inventory: InventoryIndex.render_index(index.inventory)
    }
  end
end
