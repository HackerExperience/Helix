defmodule Helix.Account.Model.Session do

  @behaviour Guardian.Serializer

  @enforce_keys [:account_id]
  defstruct [:account_id]

  @type t :: %__MODULE__{
    account_id: String.t
  }

  @spec for_token(t) :: {:ok, String.t}
  def for_token(%__MODULE__{account_id: account_id}),
    do: {:ok, account_id}

  @spec from_token(session :: String.t) :: {:ok, t}
  def from_token(session),
    do: {:ok, %__MODULE__{account_id: session}}
end