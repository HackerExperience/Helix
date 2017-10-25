defmodule Helix.Core.Repo.Migrations.AddListener do
  use Ecto.Migration

  def change do

    create table(:listeners, primary_key: false) do
      add :listener_id, :uuid, primary_key: true

      add :object_id, :string, null: false
      add :event, :uuid, null: false

      add :callback, {:array, :string}, null: false
      add :meta, :map
    end
    create index(:listeners, [:object_id, :event])

    create table(:owners, primary_key: false) do
      add :listener_id,
        references(
          :listeners, column: :listener_id, type: :uuid, on_delete: :delete_all
        ),
        primary_key: true

      add :owner_id, :string, null: false
      add :object_id, :string, null: false
      add :event, :uuid, null: false
      add :subscriber, :string, null: false
    end
    create unique_index(:owners, [:owner_id, :object_id, :event, :subscriber])
  end
end
