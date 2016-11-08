defmodule HELM.Server.Repo.Migrations.ChangePkToIp do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      remove :server_id
      remove :poi_id
      remove :motherboard_id
      add :server_id, :inet, primary_key: true
      add :poi_id, :inet
      add :motherboard_id, :inet
    end
  end
end
