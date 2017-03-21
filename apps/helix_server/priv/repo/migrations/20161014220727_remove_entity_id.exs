defmodule Helix.Server.Repo.Migrations.RemoveEntityID do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      remove :entity_id
    end
  end
end
