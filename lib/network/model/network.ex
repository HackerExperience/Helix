defmodule Helix.Network.Model.Network do

  use Ecto.Schema

  alias HELL.PK

  @type id :: PK.t
  @type t :: %__MODULE__{}

  @primary_key false
  @ecto_autogenerate {:network_id, {PK, :pk_for, [:network_network]}}
  schema "networks" do
    field :network_id, PK,
      primary_key: true

    field :name, :string
  end
end
