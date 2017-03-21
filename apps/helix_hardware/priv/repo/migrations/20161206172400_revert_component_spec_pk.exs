defmodule Helix.Hardware.Repo.Migrations.RevertComponentSpecPk do
  use Ecto.Migration

  def change do
    alter table(:components) do
      remove :spec_id
    end
    alter table(:component_specs) do
      remove :spec_id
      add :spec_id, :inet, primary_key: true
    end
    alter table(:components) do
      add :spec_id, references(:component_specs, column: :spec_id, type: :inet)
    end
  end
end
