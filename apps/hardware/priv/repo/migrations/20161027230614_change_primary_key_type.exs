defmodule HELM.Hardware.Repo.Migrations.ChangePrimaryKeyType do
  use Ecto.Migration

  def change do
    alter table(:components) do
      remove :spec_id
    end

    alter table(:component_specs) do
      remove :spec_id
      add :spec_id, :binary_id, primary_key: true
    end

    alter table(:motherboard_slots) do
      remove :slot_id
      remove :motherboard_id
      remove :link_component_id
      add :slot_id, :binary_id, primary_key: true
    end

    alter table(:components) do
      remove :component_id
      add :component_id, :binary_id, primary_key: true
      add :spec_id, references(:component_specs, column: :spec_id, type: :binary_id)
    end

    alter table(:motherboards) do
      remove :motherboard_id
      add :motherboard_id, :binary_id, primary_key: true
    end

    alter table(:motherboard_slots) do
      add :motherboard_id, references(:motherboards, column: :motherboard_id, type: :binary_id)
      add :link_component_id, references(:components, column: :component_id, type: :binary_id)
    end
  end
end