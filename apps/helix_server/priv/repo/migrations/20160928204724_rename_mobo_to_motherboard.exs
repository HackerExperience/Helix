defmodule Helix.Server.Repo.Migrations.CreateRenameMoboToMotherboard do
  use Ecto.Migration

  def change do
     rename table(:servers), :mobo_id, to: :motherboard_id
  end
end
