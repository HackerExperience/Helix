defmodule HELM.Hardware.Repo.Migrations.RemoveUselessTimestamps do
  use Ecto.Migration

  def change do
    alter table(:component_types) do
      remove :inserted_at
      remove :updated_at
    end
  end
end