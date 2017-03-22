defmodule Helix.Account.Model.SessionSerializer do

  @behaviour Guardian.Serializer

  alias Helix.Account.Model.Account

  @opaque session :: String.t

  # REVIEW: What is this expecting to receive exactly ? I'll make it temporarily
  #   just store the account's id
  @spec for_token(Account.t) :: {:ok, session}
  def for_token(%Account{account_id: account_id}),
    do: {:ok, to_string(account_id)}
  def for_token(_),
    do: {:error, "invalid input"}

  # Well. i think that this module should not be inside the model folders
  # if it depends on external data, but let's leave it as is until we fix it
  @spec from_token(session) :: {:ok, Account.t}
  def from_token(account_id) do
    Helix.Account.Controller.Account.find(account_id)
  end
end