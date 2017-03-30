defmodule Helix.Server.Repo.Migrations.AddUniqueMotherboardConstraint do
  use Ecto.Migration

  def change do
    create unique_index(:servers, [:motherboard_id])
  end
end
