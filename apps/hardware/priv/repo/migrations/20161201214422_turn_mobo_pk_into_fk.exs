defmodule Helix.Hardware.Repo.Migrations.TurnMoboPkIntoFk do
  use Ecto.Migration

  def change do
    alter table(:motherboards) do
      modify :motherboard_id, references(:components, column: :component_id, type: :inet)
    end
  end
end