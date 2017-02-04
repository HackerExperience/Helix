defmodule Helix.Process.Model.Process.MapServerToProcess do

  use Ecto.Schema

  alias HELL.PK

  import Ecto.Changeset

  @primary_key false
  schema "server_process_maps" do
    field :server_id, PK,
      primary_key: true
    field :process_id, PK,
      primary_key: true
    field :software_type, :string
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:server_id, :process_id, :software_type])
    |> validate_required([:server_id, :process_id, :software_type])
  end
end