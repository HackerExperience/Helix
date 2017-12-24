defmodule Helix.Test.Account.Setup do

  alias Ecto.Changeset
  alias Helix.Account.Action.Session, as: SessionAction
  alias Helix.Account.Internal.Account, as: AccountInternal
  alias Helix.Account.Model.Account
  alias Helix.Account.Query.Account, as: AccountQuery

  alias HELL.TestHelper.Random
  alias Helix.Test.Entity.Setup, as: EntitySetup
  alias Helix.Test.Server.Setup, as: ServerSetup

  @doc """
  - with_server: whether the created account should have a server linked to it.
    Defaults to false.

  Related data: Server.t (when `with_server` is true)
  """
  def account!(opts \\ []) do
    {account, _} = account(opts)
    account
  end

  def account(opts \\ []) do
    if opts[:with_server] do
      {server, %{entity: entity}} = ServerSetup.server()

      account =
        %Account.ID{id: entity.entity_id.id}
        |> AccountQuery.fetch()

      {account, %{server: server}}
    else
      {_, related = %{params: params}} = fake_account(opts)
      {:ok, account} = AccountInternal.create(params)

      {account, related}
    end
  end

  @doc """
  Opts:
  - username: Set account username.
  - email: Set account email.
  - password: Set account password.

  Related: Account.creation_params
  """
  def fake_account(opts \\ []) do
    username = Keyword.get(opts, :username, Random.username())
    email = Keyword.get(opts, :email, Random.email())
    password = Keyword.get(opts, :password, Random.string(length: 10))

    params =
      %{
        email: email,
        username: username,
        password: password
      }

    account =
      params
      |> Account.create_changeset()
      |> Changeset.apply_changes()

    related = %{params: params}

    {account, related}
  end

  @doc """
  - account: Which account to generate a token to
  """
  def token(opts \\ []) do
    account = Access.get(opts, :account, account!())
    {:ok, token} = SessionAction.generate_token(account)

    {token, %{account: account}}
  end
end
