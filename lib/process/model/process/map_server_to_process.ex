defmodule Helix.Process.Model.Process.MapServerToProcess do

  use Ecto.Schema

  alias Helix.Server.Model.Server
  alias Helix.Process.Model.Process

  import Ecto.Changeset

  @primary_key false
  schema "process_servers" do
    field :server_id, Server.ID,
      primary_key: true
    field :process_id, Process.ID,
      primary_key: true
    field :process_type, :string
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:server_id, :process_type])
    |> validate_required([:server_id, :process_type])
  end
end
