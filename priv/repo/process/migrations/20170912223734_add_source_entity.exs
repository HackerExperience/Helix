defmodule Helix.Process.Repo.Migrations.AddSourceEntity do
  use Ecto.Migration

  def change do
    alter table(:processes) do
      add :source_entity_id, :inet
    end
  end
end
