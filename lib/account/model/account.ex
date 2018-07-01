defmodule Helix.Account.Model.Account do

  use Ecto.Schema
  use HELL.ID, field: :account_id

  import Ecto.Changeset
  import HELL.Ecto.Macros
  import HELL.Macros

  alias Comeonin.Bcrypt
  alias Ecto.Changeset
  alias Helix.Entity.Model.Entity

  @type email :: String.t
  @type username :: String.t
  @type password :: String.t
  @type t :: %__MODULE__{
    account_id: id,
    email: email,
    username: username,
    display_name: String.t,
    password: password,
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    email: email,
    username: username,
    password: password
  }
  @type update_params :: %{
    optional(:email) => email,
    optional(:password) => password,
    optional(:confirmed) => boolean
  }

  @creation_fields ~w/email username password/a
  @update_fields ~w/email password confirmed/a

  @derive {Poison.Encoder, only: [:email, :username, :account_id]}
  schema "accounts" do
    field :account_id, ID,
      primary_key: true

    field :email, :string
    field :username, :string
    field :display_name, :string
    field :password, :string

    field :confirmed, :boolean,
      default: false

    timestamps()
  end

  @spec create_changeset(creation_params) ::
    Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
    |> prepare_changes()
    |> put_pk(%{}, :account)
  end

  @spec update_changeset(t | Changeset.t, update_params) ::
    Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> generic_validations()
    |> prepare_changes()
  end

  @spec check_password(t, password) ::
    boolean
  @doc """
  Checks if `pass` matches with `account`'s password

  This function is safe against timing attacks by always traversing the whole
  input string

  ## Examples

      iex> check_password(account, "correct password")
      true

      iex> check_password(account, "incorrect password")
      false
  """
  def check_password(account = %__MODULE__{}, pass),
    do: Bcrypt.checkpw(pass, account.password)

  @spec cast_from_entity(Entity.id) ::
    id
  @doc """
  "Translates" an Entity.id into Account.id
  """
  def cast_from_entity(entity_id = %Entity.ID{}),
    do: __MODULE__.ID.cast!(to_string(entity_id))

  @spec generic_validations(Changeset.t) ::
    Changeset.t
  defp generic_validations(changeset) do
    changeset
    |> validate_required([:email, :username, :password])
    |> validate_length(:password, min: 8)
    |> validate_change(:email, &validate_email/2)
    |> validate_change(:username, &validate_username/2)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @spec prepare_changes(Changeset.t) ::
    Changeset.t
  defp prepare_changes(changeset) do
    changeset
    |> put_display_name()
    |> update_change(:email, &String.downcase/1)
    |> update_change(:username, &String.downcase/1)
    |> update_change(:password, &Bcrypt.hashpwsalt/1)
  end

  @spec put_display_name(Changeset.t) ::
    Changeset.t
  defp put_display_name(changeset) do
    case fetch_change(changeset, :username) do
      {:ok, username} ->
        put_change(changeset, :display_name, username)
      :error ->
        changeset
    end
  end

  @spec validate_email(:email, email) ::
    []
    | [email: String.t]
  docp """
  Validates that the email is a valid email address
  """
  defp validate_email(:email, value) do
    is_binary(value)
    # TODO: Remove this regex and use something better
    && Regex.match?(~r/^[\w0-9\.\-\_\+]+@[\w0-9\.\-\_]+\.[\w0-9\-]+$/ui, value)
    && []
    || [email: "has invalid format"]
  end

  @spec validate_username(:username, username) ::
    []
    | [username: String.t]
  docp """
  Validates that the username contains just alphanumeric and `!?$%-_.`
  characters.
  """
  defp validate_username(:username, value) do
    is_binary(value)
    && Regex.match?(~r/^[a-zA-Z0-9][a-zA-Z0-9\!\?\$\%\-\_\.]{1,15}$/, value)
    && []
    || [username: "has invalid format"]
  end

  query do

    alias Helix.Account.Model.Account

    @spec by_id(Queryable.t, Account.idtb) ::
      Queryable.t
    def by_id(query \\ Account, id),
      do: where(query, [a], a.account_id == ^id)

    @spec by_email(Queryable.t, Account.email) ::
      Queryable.t
    def by_email(query \\ Account, email) do
      email = String.downcase(email)

      where(query, [a], a.email == ^email)
    end

    @spec by_username(Queryable.t, Account.username) ::
      Queryable.t
    def by_username(query \\ Account, username) do
      username = String.downcase(username)

      where(query, [a], a.username == ^username)
    end
  end
end
