defmodule Helix.Server.Repo.Migrations.ChangePrimaryKeyType do
  use Ecto.Migration

  def change do
    drop unique_index(:servers, [:server_id], name: :unique_server_id)

    alter table(:servers) do
      remove :server_id
      remove :poi_id
      remove :motherboard_id
      
      add :server_id, :binary_id, primary_key: true
      add :poi_id, :binary_id
      add :motherboard_id, :binary_id
    end
  end
end