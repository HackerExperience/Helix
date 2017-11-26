defmodule Helix.Server.Model.Component.Type do

  use Ecto.Schema

  alias HELL.Constant

  @primary_key false
  schema "component_types" do
    field :type, Constant,
      primary_key: true
  end
end
