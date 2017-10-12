defmodule Helix.Software.Model.PublicFTP do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias Hector
  alias Helix.Server.Model.Server
  alias Helix.Software.Model.File
  alias __MODULE__, as: PublicFTP

  @type t :: term

  @type changeset :: %Changeset{data: %__MODULE__{}}

  @type creation_params :: %{
    server_id: Server.id
  }

  @creation_fields [:server_id]
  @required_fields [:server_id, :is_active]

  @primary_key false
  schema "pftps" do
    field :server_id, Server.ID,
      primary_key: true

    field :is_active, :boolean

    has_many :files, PublicFTP.Files,
      foreign_key: :server_id,
      references: :server_id
  end

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> enable_server()
    |> validate_changeset()
  end

  def enable_server(entry = %__MODULE__{}) do
    entry
    |> change()
    |> enable_server()
  end

  def enable_server(changeset = %Changeset{}),
   do: put_change(changeset, :is_active, true)

  def disable_server(entry = %__MODULE__{}) do
    entry
    |> change()
    |> disable_server()
  end

  def disable_server(changeset = %Changeset{}),
    do: put_change(changeset, :is_active, false)

  defp validate_changeset(changeset) do
    changeset
    |> validate_required(@required_fields)
  end

  defmodule Query do

    import Ecto.Query

    alias Helix.Software.Model.PublicFTP

    def by_server(query \\ PublicFTP, server_id),
      do: where(query, [pf], pf.server_id == ^server_id)

    def list_files(query \\ PublicFTP, server_id) do
      sql = "
        SELECT files.*
        FROM public_ftp_files AS pftp_files
        LEFT JOIN files ON files.file_id = pftp_files.file_id
        WHERE server_id = ##1::server_id
          AND  (
            SELECT is_active
            FROM public_ftps
            WHERE server_id = ##2::server_id
          ) = TRUE
        "

      # TODO: Implement repeated params support on Hector
      Hector.query!(sql, [server_id, server_id], &HELL.Hector.caster/2)
    end
  end
end
