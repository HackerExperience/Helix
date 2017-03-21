defmodule Helix.Entity.Repo.Migrations.RemoveReferenceId do
  use Ecto.Migration

  def change do
    alter table(:entities) do
      remove :reference_id
    end
  end
end
