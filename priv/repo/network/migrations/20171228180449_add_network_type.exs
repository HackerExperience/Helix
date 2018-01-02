defmodule Helix.Network.Repo.Migrations.AddNetworkType do
  use Ecto.Migration

  def change do
    # Set internet network type to `:internet`
    execute "UPDATE networks SET type = 'internet' WHERE network_id = '::'"

    alter table(:networks, primary_key: false) do
      add :type, :string, null: false
    end

    # Network type must be one of (:internet, :story, :mission, :lan)
    execute """
    ALTER TABLE networks
      ADD CONSTRAINT networks_type_check_enum
        CHECK (type IN ('internet', 'story', 'mission', 'lan'))
    """
  end
end
