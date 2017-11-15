defmodule Helix.Server.Repo.Migrations.HardwareRewrite do
  use Ecto.Migration

  def change do
    create table(:component_types, primary_key: false) do
      add :component_type, :string, primary_key: true
    end

    create table(:component_specs, primary_key: false) do
      add :spec_id, :string, primary_key: true
      add :spec, :jsonb
      add :component_type,
        references(:component_types, column: :component_type, type: :string)
    end
  end
end
