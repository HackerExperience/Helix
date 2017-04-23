defmodule Helix.Server.Repo.Migrations.AddServerPassword do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add :password, :string, null: false
    end
  end
end
