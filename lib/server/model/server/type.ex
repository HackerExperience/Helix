defmodule Helix.Server.Model.Server.Type do

  use Ecto.Schema

  alias HELL.Constant

  @type t ::
    %__MODULE__{
      type: type
    }

  @type type ::
    :desktop
    | :mobile
    | :npc

  @server_types [:desktop, :mobile, :npc]

  @primary_key false
  schema "server_types" do
    field :type, Constant,
      primary_key: true
  end

  @spec possible_types() ::
    [type]
  def possible_types,
    do: @server_types
end
