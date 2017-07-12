defmodule Helix.Network.Repo.Migrations.Dns do
  use Ecto.Migration

  def change do
    create table(:dns_unicast, primary_key: false) do
      add :name, :string, primary_key: true
      add :ip, :inet, null: false
    end

    create unique_index(:dns_unicast, [:ip])

    create table(:dns_anycast, primary_key: false) do
      add :name, :string, primary_key: true
      add :npc_id, :inet, null: false
    end

    create unique_index(:dns_anycast, [:npc_id])
  end
end
