defmodule Helix.Process.Repo.Migrations.AddProcessData do
  use Ecto.Migration

  def change do
    alter table(:processes) do
      add :process_data, :jsonb
    end
  end
end
