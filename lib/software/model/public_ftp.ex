defmodule Helix.Software.Model.PublicFTP do
  @moduledoc """
  The PublicFTP model is responsible for handling, well, the PublicFTP model.
  """

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Hector
  alias Helix.Server.Model.Server
  alias __MODULE__, as: PublicFTP

  @type t :: %__MODULE__{
    server_id: Server.id,
    is_active: boolean
  }

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params :: %{
    server_id: Server.idtb
  }

  @creation_fields [:server_id]
  @required_fields [:server_id, :is_active]

  @primary_key false
  schema "pftps" do
    field :server_id, Server.ID,
      primary_key: true

    field :is_active, :boolean

    has_many :files, PublicFTP.File,
      foreign_key: :server_id,
      references: :server_id
  end

  @spec create_server(Server.id) ::
    changeset
  @doc """
  Creates a new PublicFTP changeset.
  """
  def create_server(server_id) do
    %{server_id: server_id}
    |> create_changeset()
  end
  @spec enable_server(t) ::
    changeset
  @doc """
  Marks a PublicFTP server as active/enabled.
  """
  def enable_server(entry = %__MODULE__{}) do
    entry
    |> change()
    |> enable_server()
  end

  @spec enable_server(changeset) ::
    changeset
  def enable_server(changeset = %Changeset{}),
   do: put_change(changeset, :is_active, true)

  @spec disable_server(t) ::
    changeset
  @doc """
  Marks a PublicFTP server as inactive/disabled.
  """
  def disable_server(entry = %__MODULE__{}) do
    entry
    |> change()
    |> disable_server()
  end

  @spec disable_server(changeset) ::
    changeset
  def disable_server(changeset = %Changeset{}),
    do: put_change(changeset, :is_active, false)

  @spec create_changeset(creation_params) ::
    changeset
  defp create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> enable_server()
    |> validate_changeset()
  end

  @spec validate_changeset(changeset) ::
    changeset
  defp validate_changeset(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  defmodule Query do

    import Ecto.Query

    alias Ecto.Queryable
    alias Helix.Server.Model.Server
    alias Helix.Software.Model.PublicFTP

    @spec by_server(Queryable.t, Server.idtb) ::
      Queryable.t
    def by_server(query \\ PublicFTP, server_id),
      do: where(query, [pf], pf.server_id == ^server_id)

    @spec list_files(Server.id) ::
      Queryable.t
    @doc """
    Lists all files on the PublicFTP server, as long as it is active. Preloads
    and returns a list of File.t, with the module association loaded.

    ## SQL

    ```
    SELECT DISTINCT ON (f.file_id) f.*
    FROM (
      SELECT file.*
      FROM pftp_files
      INNER JOIN pftps ON pftps.server_id == pftp_files.server_id
      INNER JOIN files ON files.file_id == pftp_files.file_id
      WHERE
        (pftp_files.server_id == ##1::server_id)
        AND (pftps.is_active = TRUE)
      ) AS f
    LEFT JOIN file_modules ON file_modules.file_id = f.file_id
    ```
    """
    def list_files(server_id) do
      q1 =
        from pftp_files in PublicFTP.File,
          inner_join: pftp in assoc(pftp_files, :public_ftp),
          inner_join: file in assoc(pftp_files, :file),
          where: pftp_files.server_id == ^server_id,
          where: pftp.is_active == true,
          select: file

      # Must be left join because some files do not have modules.
      from file in subquery(q1),
        left_join: modules in assoc(file, :modules),
        preload: [:modules],
        distinct: file.file_id
    end
  end
end
