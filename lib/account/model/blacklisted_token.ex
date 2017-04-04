defmodule Helix.Account.Model.BlacklistedToken do

  alias Helix.Account.Model.Session

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
    token: Session.t,
    expiration: DateTime.t
  }

  @primary_key false
  schema "blacklisted_tokens" do
    field :token, :string,
      primary_key: true

    field :expiration, :utc_datetime
  end

  @spec create(Session.t, DateTime.t) ::
    Ecto.Changeset.t
  def create(token, expiration) do
    params = %{token: token, expiration: expiration}
    cast(%__MODULE__{}, params, [:token, :expiration])
  end
end
