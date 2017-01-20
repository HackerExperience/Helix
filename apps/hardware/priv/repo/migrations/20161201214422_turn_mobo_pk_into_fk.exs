defmodule Helix.Hardware.Repo.Migrations.TurnMoboPkIntoFk do
  use Ecto.Migration

  def change do
    alter table(:motherboards) do
      modify :motherboard_id, references(:components, column: :component_id, type: :inet, on_delete: :delete_all, name: :motherboards_motherboard_id_fkey)
    end
  end
end