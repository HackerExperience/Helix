defmodule Helix.Account.Public.Index do

  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery

  @type index :: %{}

  @type rendered_index :: %{}

  @spec index(Entity.id) ::
    index
  def index(entity_id) do
      mainframe =
        entity_id
        |> EntityQuery.fetch()
        |> EntityQuery.get_servers()
        |> List.first()

      %{
        mainframe: mainframe
      }
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
      %{
        mainframe: to_string(index.mainframe)
      }
  end
end
