defmodule Helix.Hardware.Repo.Migrations.ComponentSpecIdToSpecCode do
  use Ecto.Migration

  def change do
    alter table(:components) do
      remove :spec_id
    end

    alter table(:component_specs) do
      remove :spec_id
      add :spec_code, :string, primary_key: true
    end

    alter table(:components) do
      add :spec_code, references(:component_specs, column: :spec_code, type: :string)
    end
  end
end
