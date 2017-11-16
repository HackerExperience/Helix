defmodule Helix.Server.Repo.Migrations.HardwareRewrite do
  use Ecto.Migration

  def change do
    create table(:component_types, primary_key: false) do
      add :component_type, :string, primary_key: true
    end

    create table(:component_specs, primary_key: false) do
      add :spec_id, :string, primary_key: true
      add :data, :jsonb
      add :component_type,
        references(:component_types, column: :component_type, type: :string)
    end

    create table(:components, primary_key: false) do
      add :component_id, :inet, primary_key: true

      add :custom, :map, null: false

      add :type,
        references(:component_types, column: :component_type, type: :string),
        null: false
      add :spec_id,
        references(:component_specs, column: :spec_id, type: :string),
        null: false
    end

    create table(:motherboards, primary_key: false) do
      add :motherboard_id,
        references(
          :components,
          column: :component_id,
          type: :inet,
          on_delete: :delete_all
        ),
        primary_key: true
      add :slot_id, :integer, primary_key: true

      add :linked_component_id,
        references(:components, column: :component_id, type: :inet)
      add :linked_component_type,
        references(:component_types, column: :component_type, type: :string)
    end

    # One component may be linked only at one motherboard at any given time
    create unique_index(:motherboards, [:linked_component_id])
  end
end
