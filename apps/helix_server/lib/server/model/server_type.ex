defmodule Helix.Server.Model.ServerType do

  use Ecto.Schema

  @type t :: %__MODULE__{
    server_type: String.t
  }

  @primary_key false
  schema "server_types" do
    field :server_type, :string,
      primary_key: true
  end

  @doc false
  def possible_types do
    ~w/desktop mobile vps/
  end
end