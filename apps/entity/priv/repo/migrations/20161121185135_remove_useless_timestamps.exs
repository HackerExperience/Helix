defmodule HELM.Entity.Repo.Migrations.RemoveUselessTimestamps do
  use Ecto.Migration

  def change do
    alter table(:entity_type, primary_key: false) do
      remove :inserted_at
      remove :updated_at
    end

    alter table(:entity_servers, primary_key: false) do
      remove :inserted_at
      remove :updated_at
    end
  end
end