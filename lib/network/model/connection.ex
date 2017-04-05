defmodule Helix.Network.Model.Connection do

  use Ecto.Schema

  alias HELL.PK

  # TODO: ConnectionType as a constant

  @primary_key false
  @ecto_autogenerate {:connection_id, {PK, :pk_for, [:network_connection]}}
  schema "connections" do
    field :connection_id, PK,
      primary_key: true
    field :tunnel_id, PK

    field :connection_type, :string
  end
end
