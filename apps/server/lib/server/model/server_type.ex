defmodule HELM.Server.Model.ServerType do

  use Ecto.Schema

  alias HELM.Server.Model.Server, as: MdlServer, warn: false
  import Ecto.Changeset

  @type t :: %__MODULE__{
    server_type: String.t,
    servers: [MdlServer.t]
  }

  @creation_fields ~w/server_type/a

  @primary_key false
  schema "server_types" do
    field :server_type, :string,
      primary_key: true

    has_many :servers, MdlServer,
      foreign_key: :server_type,
      references: :server_type
  end

  @spec create_changeset(%{server_type: String.t}) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:server_type)
    |> unique_constraint(:server_type)
  end
end