defmodule Helix.Account.Event.Account do

  import Helix.Event

  event Created do
    @moduledoc """
    `AccountCreatedEvent` is fired right after a user signed up. It is still
    pending email verification (in fact the verification email hasn't been sent
    yet, as it will be sent as a reaction to this event).
    """

    alias Helix.Account.Model.Account

    event_struct [:account]

    @type t ::
      %__MODULE__{
        account: Account.t
      }

    @spec new(Account.t) ::
      t
    def new(account = %Account{}) do
      %__MODULE__{
        account: account
      }
    end
  end

  event Verified do
    @moduledoc """
    `AccountVerifiedEvent` is fired after a user has verified her email address.
    After this point it's safe to assume the account is valid and the underlying
    account data should be generated (servers, storyline missions, etc).
    """

    alias Helix.Account.Model.Account

    event_struct [:account]

    @type t ::
      %__MODULE__{
        account: Account.t
      }

    @spec new(Account.t) ::
      t
    def new(account = %Account{}) do
      %__MODULE__{
        account: account
      }
    end
  end
end
