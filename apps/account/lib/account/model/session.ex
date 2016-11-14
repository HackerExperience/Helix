defmodule HELM.Account.Model.Session do
  @behaviour Guardian.Serializer

  @enforce_keys [:account_id]
  defstruct [:account_id]

  @spec for_token(session :: %__MODULE__{}) :: String.t
  def for_token(session = %__MODULE__{}),
    do: {:ok, session.account_id}

  @spec from_token(token :: String.t) :: %__MODULE__{}
  def from_token(token),
    do: {:ok, %__MODULE__{account_id: token}}
end