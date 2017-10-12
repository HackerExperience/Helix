defmodule Helix.Software.Model.PublicFTP.Files do

  use Ecto.Schema

  import Ecto.Changeset

  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP

  @creation_fields [:server_id, :file_id]
  @required_fields [:server_id, :file_id, :inserted_at]

  @primary_key false
  schema "pftp_files" do
    field :server_id, Server.ID,
      primary_key: true

    field :file_id, File.ID
    field :inserted_at, :utc_datetime

    belongs_to :file, File,
      foreign_key: :file_id,
      references: :file_id,
      define_field: false

    belongs_to :public_ftp, PublicFTP,
      foreign_key: :server_id,
      references: :server_id,
      define_field: false
  end

  def add_file(server_id, file_id) do
    %{server_id: server_id, file_id: file_id}
    |> create_changeset()
  end

  defp create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> add_timestamp()
    |> validate_changeset()
  end

  defp validate_changeset(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  defp add_timestamp(changeset),
    do: put_change(changeset, :inserted_at, DateTime.utc_now())
end
