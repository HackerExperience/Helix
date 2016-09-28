defmodule HELM.Server.Repo.Migrations.AddServerType do
  use Ecto.Migration

  def change do
    alter table(:servers) do
      add :server_type, :string
    end
  end
end
