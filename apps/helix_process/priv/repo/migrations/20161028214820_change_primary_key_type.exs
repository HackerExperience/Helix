defmodule Helix.Process.Repo.Migrations.ChangePrimaryKeyType do
  use Ecto.Migration

  def change do
    drop unique_index(:processes, [:process_id], name: :unique_process_id)

    alter table(:processes) do
      remove :process_id
      add :process_id, :binary_id, primary_key: true
    end
  end
end