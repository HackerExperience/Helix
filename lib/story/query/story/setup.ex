defmodule Helix.Story.Query.Story.Setup do
  @moduledoc """
  `StoryQuery.Setup` is a helper tailored for idempotent Step Setups. It should
  only be used within that context!

  It will check whether the item (:file, :server, :pftp_file, :char, ...) exists
  *and* is valid within the reasonable step context.

  For instance, a file that is hidden will, by default, return `nil` even if it
  does exist.

  If the Step wants a more flexible approach (e.g. hidden files are OK, but
  encrypted ones aren't), the `opts` argument should be used for specificity.

  ### Return format

  In case of failure (object was not found OR object is not deemed valid
  according to the given `opts`), it should always return `nil`.

  Otherwise, if the object was found, it must return the same format of Make*
  files, which is:

  {:ok, `item`, `related`, `events`} where:

  - `item` is the object / struct that is being requested
  - `related` is a map of values related to `item`. Usually it's empty.
  - `events` is a list of events that should be emitted. Almost always it's an
    empty list.
  """

  import Helix.Story.Model.Step.Macros.Setup

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

  @typep opts :: list

  @spec find_char({Entity.id, Step.contact_id}, opts) ::
    {:ok, Server.t, %{entity: Entity.t}, list}
    | nil
  @doc """
  Checks whether the `char` exists.

  - A Context.t must exist for the given {`entity_id`, `contact_id`}
  - The contact's server must exist
  - The contact's entity must exist
  """
  find :char, {entity_id = %Entity.ID{}, contact_id} do
    with \
      context = %{} <- ContextQuery.get(entity_id, contact_id),
      server = %{} <- ServerQuery.fetch(context.server_id),
      entity = %{} <- EntityQuery.fetch(context.entity_id)
    do
      {:ok, server, %{entity: entity}, []}
    end
  end

  @spec find_file(File.idt, opts) ::
    {:ok, File.t, %{}, list}
    | nil
  @doc """
  Checks whether the `file` exists

  - File must exist
  - File must not be hidden (NOTYET)
  - File must not be encrypted (NOTYET)
  """
  find :file, %File{}, get: :file_id
  find :file, file_id = %File.ID{} do
    with file = %{} <- FileQuery.fetch(file_id) do
      {:ok, file, %{}, []}
    end
  end

  @spec find_pftp_server(Server.idt, opts) ::
    {:ok, PublicFTP.t, %{}, list}
    | nil
  @doc """
  Checks whether the PublicFTP server exists.

  - PFTPServer must exist for the given server
  - PFTPServer must be enabled
  """
  find :pftp_server, %Server{}, get: :server_id
  find :pftp_server, server_id = %Server.ID{} do
    with \
      pftp = %{} <- PublicFTPQuery.fetch_server(server_id),
      true <- PublicFTP.is_active?(pftp)
    do
      {:ok, pftp, %{}, []}
    end
  end

  @spec find_pftp_file(File.idt, opts) ::
    {:ok, PublicFTP.File.t, %{}, list}
    | nil
  @doc """
  Checks whether the File is added to the PublicFTP Server.

  - PublicFTP Server must exist (indirect check)
  - PublicFTP Server must be enabled (indirect check)
  - File must be added to the PublicFTP Server
  """
  find :pftp_file, %File{}, get: :file_id
  find :pftp_file, file_id = %File.ID{} do
    with pftp_file = %{} <- PublicFTPQuery.fetch_file(file_id) do
      {:ok, pftp_file, %{}, []}
    end
  end
end
