defmodule HELM.Account.Model.Session do
  @behaviour Guardian.Serializer

  def for_token(%{account_id: account_id}),
    do: {:ok, account_id}

  def from_token(account_id),
    do: {:ok, account_id}
end