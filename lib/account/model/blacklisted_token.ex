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

  @spec create_changeset(%{token: Session.t}) ::
    Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, [:token])
    |> validate_required([:token])
    |> validate_length(:token, max: 1024)
    |> add_expiration()
  end

  defp add_expiration(changeset) do
    token = get_field(changeset, :token)

    case Guardian.decode_and_verify(token) do
      {:ok, claims} ->
        exp =  DateTime.from_unix!(claims["exp"])

        cast(changeset, %{exp: exp}, [:exp])
      {:error, _} ->
        add_error(changeset, :token, "is invalid")
    end
  end
end
