defmodule HELM.Server.Repo.Migrations.RemoveUselessTimestamps do
  use Ecto.Migration

  def change do
    alter table(:server_types) do
      remove :inserted_at
      remove :updated_at
    end
  end
end