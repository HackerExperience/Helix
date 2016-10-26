defmodule HELM.Server.Model.ServerTypes do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Server.Model.Servers, as: MdlServers

  @primary_key {:server_type, :string, autogenerate: false}
  @creation_fields ~w/server_type/a

  schema "server_types" do
    has_many :servers, MdlServers,
      foreign_key: :server_type,
      references: :server_type

    timestamps
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:server_type)
  end
end