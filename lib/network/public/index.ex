defmodule Helix.Network.Public.Index do

  alias Helix.Server.Model.Server

  @type index ::
    term

  @type rendered_index ::
    term

  @spec index(Server.id) ::
    index
  def index(_server_id) do
    []
  end

  @spec render_index(index) ::
    term
  def render_index(_index) do
    []
  end
end
