defmodule HELM.Auth.GuardianSerializer do
  @behaviour Guardian.Serializer

  # Serialize

  def for_token(%{account_id: account_id}) do
    { :ok, account_id }
  end

  def for_token(_), do: { :error, "Unknown resource type" }

  # Unserialize

  def from_token(account_id) do
    {:ok, %{account_id: account_id}}
  end

  def from_token(_), do: { :error, "Unknown resource type" }
end
