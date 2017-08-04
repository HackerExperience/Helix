defmodule Helix.Network.Model.Network do

  use Ecto.Schema
  use HELL.ID, field: :network_id, meta: [0x0000]

  alias HELL.IPv4

  @type t :: %__MODULE__{
    network_id: id,
    name: String.t
  }
  @type nip :: %{
    network_id: id,
    ip: IPv4.t
  }

  schema "networks" do
    field :network_id, ID,
      primary_key: true

    field :name, :string
  end
end
