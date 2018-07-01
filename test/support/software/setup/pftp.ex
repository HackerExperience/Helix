defmodule Helix.Test.Software.Setup.PFTP do

  alias Ecto.Changeset
  alias Helix.Software.Model.PublicFTP
  alias Helix.Software.Repo, as: SoftwareRepo

  alias Helix.Test.Server.Helper, as: ServerHelper
  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Software.Helper, as: SoftwareHelper
  alias Helix.Test.Software.Setup, as: SoftwareSetup

  @doc """
  See docs on `fake_pftp/1`
  """
  def pftp(opts \\ []) do
    {pftp, related} = fake_pftp(opts)

    {:ok, inserted} = SoftwareRepo.insert(pftp)

    {inserted, related}
  end

  @doc """
  Opts:
  - server_id: Specify the server id. Defaults to generating a fake server id.
  - active: Whether the generated pftp should be active. Defaults to true.
  - real_server: Whether to generate a real server (desktop). Defaults to false.

  Related: Server.t if `real_server`
  """
  def fake_pftp(opts \\ []) do
    if opts[:server_id] != nil and opts[:real_server] != nil do
      raise "Cant use both `real_server` and `server_id` opts"
    end

    is_active = Keyword.get(opts, :active, true)

    {server, server_id} =
      cond do
        opts[:real_server] ->
          {server, _} = ServerSetup.server()
          {server, server.server_id}
        opts[:server_id] ->
          {nil, opts[:server_id]}
        true ->
          {nil, ServerHelper.id()}
      end

    pftp =
      server_id
      |> PublicFTP.create_server()
      |> Changeset.force_change(:is_active, is_active)
      |> Changeset.apply_changes()

    related =
      if server do
        %{server: server}
      else
        %{}
      end

    {pftp, related}
  end

  @doc """
  See doc on `fake_file/1`
  """
  def file(opts \\ []) do
    {pftp_file, related} = fake_file(opts)

    {:ok, inserted} = SoftwareRepo.insert(pftp_file)

    {inserted, related}
  end

  @doc """
  - file_id: Specify file id. Generates a real file if not specified.
  - real_file: Whether to generate a real file. Defaults to true. Overwrites the
    `file_id` option when set.
  - server_id: Which pftp server to link to. Generates a real pftp by default

  Related:
    File.t if `real_file` is true (default), \
    PublicFTP.t when `server_id` isnt specified, \
    Server.id,
    File.id
  """
  def fake_file(opts \\ []) do
    if opts[:file_id] != nil and is_nil(opts[:server_id]),
      do: raise "pls specify both `file_id` and `server_id`"

    {file, file_id, server_id} =
      cond do
        opts[:real_file] == false ->
          {nil, SoftwareHelper.id(), ServerHelper.id()}

        opts[:file_id] ->
          {nil, opts[:file_id], opts[:server_id]}

        true ->
          server_id = Keyword.get(opts, :server_id, ServerHelper.id())
          {file, _} = SoftwareSetup.file(server_id: server_id)
          {file, file.file_id, server_id}
      end

    pftp =
      if opts[:server_id] do
        nil
      else
        pftp(server_id: server_id)
      end

    pftp_file =
      server_id
      |> PublicFTP.File.add_file(file_id)
      |> Changeset.apply_changes()

    related = %{
      pftp: pftp,
      server_id: server_id,
      file: file,
      file_id: file_id
    }

    {pftp_file, related}
  end
end
