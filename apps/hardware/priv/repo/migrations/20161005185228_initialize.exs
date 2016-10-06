defmodule HELM.Hardware.Repo.Migrations.Initialize do
  use Ecto.Migration

  def change do
    create table(:component_types, primary_key: false) do
      add :component_type, :string, primary_key: true

      timestamps
    end

    create table(:component_specs, primary_key: false) do
      add :spec_id, :string, primary_key: true
      add :component_type, references(:component_types, column: :component_type, type: :string)
      add :spec, :jsonb

      timestamps
    end

    create table(:components, primary_key: false) do
      add :component_id, :string, primary_key: true
      add :component_type, references(:component_types, column: :component_type, type: :string)
      add :spec_id, references(:component_specs, column: :spec_id, type: :string)

      timestamps
    end

    create table(:motherboards, primary_key: false) do
      add :motherboard_id, :string, primary_key: true

      timestamps
    end

    create table(:motherboard_slots) do
      add :slot_id, :string, primary_key: true
      add :motherboard_id, references(:motherboards, column: :motherboard_id, type: :string)
      add :link_component_type, references(:component_types, column: :component_type, type: :string)
      add :link_component_id, references(:components, column: :component_id, type: :string)
      add :slot_internal_id, :integer

      timestamps
    end
  end
end
