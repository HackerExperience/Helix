defmodule Helix.Network.Repo.Migrations.AddConnectionMeta do
  use Ecto.Migration

  def change do
    alter table(:connections) do
      add :meta, :map
    end
  end
end
