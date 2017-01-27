defmodule Helix.Account.Model.Account do

  use Ecto.Schema

  alias HELL.PK
  alias Comeonin.Bcrypt

  import Ecto.Changeset
  import HELL.MacroHelpers

  @type id :: String.t
  @type email :: String.t
  @type password :: String.t
  @type t :: %__MODULE__{
    account_id: PK.t,
    email: email,
    password: password,
    password_confirmation: password,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    account_id: PK.t,
    email: email,
    password: password,
    password_confirmation: password}
  @type update_params :: %{
    optional(:email) => email,
    optional(:password) => password,
    optional(:confirmed) => boolean}

  @creation_fields ~w/account_id email password password_confirmation/a
  @update_fields ~w/email password confirmed/a

  @derive {Poison.Encoder, only: [:email, :account_id]}
  @primary_key false
  schema "accounts" do
    field :account_id, HELL.PK,
      primary_key: true

    field :email, :string
    field :confirmed, :boolean,
      default: false
    field :password, :string
    field :password_confirmation, :string,
      virtual: true

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
    |> prepare_changes()
    |> put_primary_key()
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  def put_primary_key(changeset) do
    pk = PK.generate([0x0000, 0x0000, 0x0000])
    cast(changeset, %{account_id: pk}, [:account_id])
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.f
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> generic_validations()
    |> prepare_changes()
  end

  @spec generic_validations(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp generic_validations(changeset) do
    changeset
    |> validate_required([:email, :password])
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password, required: true)
    |> unique_constraint(:email, name: :unique_account_email)
    |> validate_change(:email, &validate_email/2)
  end

  @spec prepare_changes(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp prepare_changes(changeset) do
    changeset
    |> update_change(:email, &String.downcase/1)
    |> update_change(:password, &Bcrypt.hashpwsalt/1)
  end

  @spec validate_email(:email, String.t) :: [] | [email: String.t]
  docp """
  Validates that the email is a valid email address

  TODO: Remove this regex and use something better
  """
  defp validate_email(:email, value) do
    is_binary(value)
    && Regex.match?(~r/^[\w0-9\.\-\_\+]+@[\w0-9\.\-\_]+\.[\w0-9\-]+$/ui, value)
    && []
    || [email: "invalid value"]
  end
end