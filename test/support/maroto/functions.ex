defmodule Helix.Maroto.Functions do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow

  alias HELL.TestHelper.Random

  defmacro __using__(_) do
    quote do

      import Helix.Maroto.Functions
      import Helix.Maroto.ClientTools

    end
  end

  @doc """
  Opts:

  - email: email
  - user: Username.
  - pass: Password.
  """
  def create_account(opts \\ []) do
    email = Keyword.get(opts, :email, Random.email())
    user = Keyword.get(opts, :user, Random.username())
    pass = Keyword.get(opts, :pass, Random.string(min: 8, max: 10))

    related = %{email: email, user: user, pass: pass}

    {:ok, account} = AccountFlow.create(email, user, pass)

    {account, related}
  end
end
