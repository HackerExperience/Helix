defmodule Helix.Software.Model.PublicFTP.File do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP

  @type t :: %__MODULE__{
    server_id: Server.id,
    file_id: File.id,
    inserted_at: DateTime.t
  }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params :: %{
    server_id: Server.idtb,
    file_id: File.idtb
  }

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

  @spec add_file(Server.id, File.id) ::
    changeset
  def add_file(server_id, file_id) do
    %{server_id: server_id, file_id: file_id}
    |> create_changeset()
  end

  @spec create_changeset(creation_params) ::
    changeset
  defp create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> add_timestamp()
    |> validate_changeset()
  end

  @spec validate_changeset(changeset) ::
    changeset
  defp validate_changeset(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  @spec add_timestamp(changeset) ::
    changeset
  defp add_timestamp(changeset),
    do: put_change(changeset, :inserted_at, DateTime.utc_now())

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Software.Model.File
    alias Helix.Software.Model.PublicFTP

    @spec by_file(Queryable.t, File.idtb) ::
      Queryable.t
    @doc """
    Searches by file, returning only if the underlying PFTP server is active.
    """
    def by_file(query \\ PublicFTP.File, file_id) do
      query
      |> join(:inner, [pf, p], pf in PublicFTP, pf.server_id == p.server_id)
      |> where([pf, p], pf.file_id == ^file_id and p.is_active == true)
    end
  end
end
