defmodule HELM.Account.Serializer do
  @behaviour Guardian.Serializer

  alias HELM.Account.{Model, Repo}

  def for_token(account = %Model{}), do: { :ok, "Account:#{account.account_id}" }
  def for_token(_), do: { :error, "Unknown resource type" }

  def from_token("Account:" <> id), do: { :ok, Repo.get(Model, id) }
  def from_token(_), do: { :error, "Unknown resource type" }
end
