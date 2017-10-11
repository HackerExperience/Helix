defmodule Helix.Account.Event.Account do

  import Helix.Event

  event Created do

    alias Helix.Account.Model.Account

    @type t ::
      %__MODULE__{
        account: Account.t
      }

    event_struct [:account]

    @spec new(Account.t) ::
      t
    def new(account = %Account{}) do
      %__MODULE__{
        account: account
      }
    end
  end
end
