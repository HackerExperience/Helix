defmodule Helix.Process.Repo.Migrations.AddConnectionToProcess do
  use Ecto.Migration

  def change do
    alter table(:processes) do
      # NOTE: We are not dropping network_id because network_id is to know from
      #   which network to use the resources and connection_id is to kill the
      #   process when the connection is shut
      add :connection_id, :inet
    end
  end
end
