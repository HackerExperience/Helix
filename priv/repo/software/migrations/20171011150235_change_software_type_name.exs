defmodule Helix.Software.Repo.Migrations.ChangeSoftwareTypeName do
  use Ecto.Migration

  def change do

    rename table(:software_types), :software_type, to: :type

  end
end
