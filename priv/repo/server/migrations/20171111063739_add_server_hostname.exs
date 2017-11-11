defmodule Helix.Server.Repo.Migrations.AddServerHostname do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add :hostname, :string
    end
  end
end
