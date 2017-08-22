defmodule Helix.Test.Account.Setup do

  alias Helix.Account.Model.Account
  alias Helix.Account.Query.Account, as: AccountQuery

  alias Helix.Test.Server.Setup, as: ServerSetup
  alias Helix.Test.Account.Factory, as: AccountFactory

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
      account =
        AccountFactory.insert(:account)

      {account, %{}}
    end
  end

  alias Helix.Account.Action.Session, as: SessionAction
  @doc """
  - account: Which account to generate a token to
  """
  def token(opts \\ []) do
    account = Access.get(opts, :account, account!())
    {:ok, token} = SessionAction.generate_token(account)

    {token, %{account: account}}
  end
end
