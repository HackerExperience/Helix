defmodule Helix.Entity.Repo.Migrations.InitialEntityDomain do
  use Ecto.Migration

  def change do
    create table(:entity_types, primary_key: false) do
      add :entity_type,
        :string,
        primary_key: true
    end

    create table(:entities, primary_key: false) do
      add :entity_id,
        :inet,
        primary_key: true
      add :entity_type,
        references(
          :entity_types,
          column: :entity_type,
          type: :string)

      timestamps()
    end

    create table(:entity_servers, primary_key: false) do
      add :server_id,
        :inet,
        primary_key: true
      add :entity_id,
        references(
          :entities,
          column: :entity_id,
          type: :inet),
        primary_key: true
    end

    create table(:entity_components, primary_key: false) do
      add :entity_id,
        references(
          :entities,
          column: :entity_id,
          type: :inet,
          on_delete: :delete_all),
        primary_key: true
      add :component_id,
        :inet,
        primary_key: true
    end
  end
end
