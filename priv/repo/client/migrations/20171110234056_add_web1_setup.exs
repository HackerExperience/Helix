defmodule Helix.Client.Repo.Migrations.AddWeb1Setup do
  use Ecto.Migration

  def change do
    create table(:web1_setup, primary_key: false) do
      add :entity_id, :inet, primary_key: true

      add :pages, {:array, :string}
    end
  end
end
