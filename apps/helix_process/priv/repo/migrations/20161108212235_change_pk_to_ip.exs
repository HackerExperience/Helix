defmodule Helix.Process.Repo.Migrations.ChangePkToIp do
  use Ecto.Migration

  def change do
    alter table(:processes) do
      remove :process_id
      add :process_id, :inet, primary_key: true
    end
  end
end
