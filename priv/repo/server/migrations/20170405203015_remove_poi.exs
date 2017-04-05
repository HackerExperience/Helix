defmodule Helix.Server.Repo.Migrations.RemovePoi do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      remove :poi_id
    end
  end
end
