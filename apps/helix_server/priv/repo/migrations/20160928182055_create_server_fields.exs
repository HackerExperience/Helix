defmodule Helix.Server.Repo.Migrations.CreateServerFields do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add :entity_id, :string
      add :poi_id, :string
      add :mobo_id, :string
    end
  end
end
