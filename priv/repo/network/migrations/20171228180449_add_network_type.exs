defmodule Helix.Network.Repo.Migrations.AddNetworkType do
  use Ecto.Migration

  def change do
    alter table(:networks, primary_key: false) do
      add :type, :string, null: false, default: "internet"
    end

    # Alter the `type` column to drop the temporary default `internet`
    # (`internet` is used as temporary default so any existing entries - ie the
    # only existing entry, the Internet - can be properly updated)
    execute """
    ALTER TABLE "networks" ALTER COLUMN "type" DROP DEFAULT
    """

    # Network type must be one of (:internet, :story, :mission, :lan)
    execute """
    ALTER TABLE networks
      ADD CONSTRAINT networks_type_check_enum
        CHECK (type IN ('internet', 'story', 'mission', 'lan'))
    """
  end
end
