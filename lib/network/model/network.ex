defmodule Helix.Network.Model.Network do

  use Ecto.Schema
  use HELL.ID, field: :network_id, meta: [0x0000]

  alias HELL.IPv4

  @type t :: %__MODULE__{
    network_id: id,
    name: name
  }

  @type name :: String.t
  @type ip :: IPv4.t

  @type nip :: %{
    network_id: id,
    ip: ip
  }

  schema "networks" do
    field :network_id, ID,
      primary_key: true

    field :name, :string
  end

  defmodule Query do
    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Network.Model.Network

    @spec by_id(Queryable.t, Network.idtb) ::
      Queryable.t
    def by_id(query \\ Network, id),
      do: where(query, [n], n.network_id == ^id)
  end
end
