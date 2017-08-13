defmodule Helix.Network.Repo.Migrations.Webserver do
  use Ecto.Migration

  def change do
    create table(:webservers, primary_key: false) do
      add :ip, :inet, primary_key: true
      add :content, :string, size: 2048
    end
  end
end
