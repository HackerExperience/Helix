defmodule Helix.Hardware.Repo.Migrations.SetMotherboardSlotsTriggers do
  use Ecto.Migration

  def change do
    alter table(:motherboard_slots) do
      remove :motherboard_id
      add :motherboard_id, references(:motherboards, column: :motherboard_id, type: :inet, on_delete: :delete_all)
    end
  end
end
