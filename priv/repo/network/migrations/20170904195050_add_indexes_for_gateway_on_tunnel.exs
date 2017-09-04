defmodule Helix.Network.Repo.Migrations.AddIndexesForGatewayOnTunnel do
  use Ecto.Migration

  def change do
    # Below indexes are specially useful when figuring out which tunnels or
    # connections are incoming/outgoing to the specific server.
    create index(:tunnels, [:gateway_id])
    create index(:tunnels, [:destination_id])
  end
end
