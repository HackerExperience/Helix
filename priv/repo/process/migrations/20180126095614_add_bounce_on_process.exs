defmodule Helix.Process.Repo.Migrations.AddBounceOnProcess do
  use Ecto.Migration

  def change do
    # Also add `bounce_id` information on process table
    alter table(:processes, primary_key: false) do
      add :bounce_id, :inet
    end
  end
end
