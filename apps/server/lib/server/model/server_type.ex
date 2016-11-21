defmodule HELM.Server.Model.ServerType do

  use Ecto.Schema
  import Ecto.Changeset

  alias HELM.Server.Model.Server, as: MdlServer, warn: false

  @primary_key {:server_type, :string, autogenerate: false}
  @creation_fields ~w/server_type/a

  schema "server_types" do
    has_many :servers, MdlServer,
      foreign_key: :server_type,
      references: :server_type
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:server_type)
    |> unique_constraint(:server_type)
  end
end