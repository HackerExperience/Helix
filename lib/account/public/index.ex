defmodule Helix.Account.Public.Index do

  @type index :: term

  @type rendered_index :: term

  @spec index() ::
    index
  def index do
    %{}
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    index
  end
end
