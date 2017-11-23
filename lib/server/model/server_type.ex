defmodule Helix.Server.Model.ServerType do

  use Ecto.Schema

  alias HELL.Constant

  @type t :: %__MODULE__{
    server_type: Constant.t
  }

  @primary_key false
  schema "server_types" do
    field :server_type, Constant,
      primary_key: true
  end

  @doc false
  def possible_types do
    ~w/desktop mobile npc/a
  end
end
