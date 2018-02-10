defmodule Helix.Story.Model.Step.Macros.Setup do

  alias HELL.Utils
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Entity, as: EntityQuery
  alias Helix.Server.Model.Server
  alias Helix.Server.Query.Server, as: ServerQuery
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Query.PublicFTP, as: PublicFTPQuery
  alias Helix.Story.Model.Step
  alias Helix.Story.Query.Context, as: ContextQuery

  @spec find_char({Entity.id, Step.contact_id}, []) ::
    {:ok, Server.t, %{entity: Entity.t}, []}
    | nil
  def find_char({entity_id = %Entity.ID{}, contact_id}, _opts) do
    with \
      context = %{} <- ContextQuery.get(entity_id, contact_id),
      server = %{} <- ServerQuery.fetch(context.server_id),
      entity = %{} <- EntityQuery.fetch(context.entity_id)
    do
      {:ok, server, %{entity: entity}, []}
    end
  end

  def find_file(nil, _),
    do: nil
  def find_file(file_id = %File.ID{}, _opts) do
    with file = %{} <- FileQuery.fetch(file_id) do
      {:ok, file, %{}, []}
    end
  end

  def find_pftp_server(nil, _opts),
    do: nil
  def find_pftp_server(server = %Server{}, opts),
    do: find_pftp_server(server.server_id, opts)
  def find_pftp_server(server_id = %Server.ID{}, _opts) do
    with \
      pftp = %{} <- PublicFTPQuery.fetch_server(server_id),
      true <- PublicFTP.is_active?(pftp) || nil
    do
      {:ok, pftp, %{}, []}
    end
  end

  def find_pftp_file(nil, _opts),
    do: nil
  def find_pftp_file(file = %File{}, opts),
    do: find_pftp_file(file.file_id, opts)
  def find_pftp_file(file_id = %File.ID{}, _opts) do
    with pftp_file = %{} <- PublicFTPQuery.fetch_file(file_id) do
      {:ok, pftp_file, %{}, []}
    end
  end
end
