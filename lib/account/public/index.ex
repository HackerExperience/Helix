defmodule Helix.Account.Public.Index do

  alias Helix.Entity.Model.Entity

  @type index :: %{}

  @type rendered_index :: %{}

  @spec index(Entity.id) ::
    index
  def index(_entity_id) do
    %{}
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(_index) do
    %{}
  end
end
