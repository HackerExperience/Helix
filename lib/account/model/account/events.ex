defmodule Helix.Account.Model.Account.AccountCreatedEvent do
  @moduledoc false

  @enforce_keys [:account_id]
  defstruct [:account_id]
end
