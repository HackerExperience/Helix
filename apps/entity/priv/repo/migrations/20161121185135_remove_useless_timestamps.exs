defmodule HELM.Entity.Repo.Migrations.RemoveUselessTimestamps do
  use Ecto.Migration

  def change do
    alter table(:entity_types) do
      remove :inserted_at
      remove :updated_at
    end

    alter table(:entity_servers) do
      remove :inserted_at
      remove :updated_at
    end
  end
end