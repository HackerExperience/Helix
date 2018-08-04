defmodule Helix.Process.Repo.Migrations.AddTargetLog do
  use Ecto.Migration

  def change do
    alter table(:processes, primary_key: false) do
      add :tgt_log_id, :inet
    end

    create index(:processes, [:tgt_log_id], where: "tgt_log_id IS NOT NULL")
  end
end
