defmodule Helix.Account.Model.BlacklistedToken do

  alias Helix.Account.Model.Session

  use Ecto.Schema

  import Ecto.Changeset

  @type t :: %__MODULE__{
    token: Session.t,
    exp: DateTime.t
  }

  @primary_key false
  schema "blacklisted_tokens" do
    field :token, :string,
      primary_key: true

    field :exp, :utc_datetime
  end

  @spec create(Session.t, DateTime.t) ::
    Ecto.Changeset.t
  def create(token, exp),
    do: cast(%__MODULE__{}, %{token: token, exp: exp}, [:token, :exp])
end
