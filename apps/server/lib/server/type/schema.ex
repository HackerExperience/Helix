defmodule HELM.Server.Type.Schema do
  use Ecto.Schema

  import Ecto.Changeset

  alias HELM.Server.Schema, as: ServerSchema

  @primary_key {:server_type, :string, autogenerate: false}
  @creation_fields ~w/server_type/a

  schema "server_types" do
    has_many :servers, ServerSchema,
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
