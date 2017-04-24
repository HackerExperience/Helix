defmodule Helix.Account.Model.Account do

  use Ecto.Schema

  alias HELL.PK
  alias Comeonin.Bcrypt

  import Ecto.Changeset
  import HELL.MacroHelpers

  @type id :: PK.t
  @type email :: String.t
  @type username :: String.t
  @type password :: String.t
  @type t :: %__MODULE__{
    account_id: PK.t,
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
  @primary_key false
  @ecto_autogenerate {:account_id, {PK, :pk_for, [:account_account]}}
  schema "accounts" do
    field :account_id, HELL.PK,
      primary_key: true

    field :email, :string
    field :username, :string
    field :display_name, :string
    field :confirmed, :boolean,
      default: false
    field :password, :string

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> generic_validations()
    |> prepare_changes()
  end

  @spec update_changeset(t, update_params) :: Ecto.Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> generic_validations()
    |> prepare_changes()
  end

  @default_pass_for_timing_attacks Bcrypt.hashpwsalt("Avoid timing attacks")

  @spec check_password(t | nil, password) :: boolean
  @doc """
  Checks if `pass` matches with `account`'s password

  This function is safe against timing attacks by having a default clause for
  when the input account is nil that will still compare hash of a potential
  password thus taking the same time to be executed

  ## Examples

      iex> check_password(account, "correct password")
      true

      iex> check_password(nil, "some password")
      false

      iex> check_password(account, "incorrect password")
      false
  """
  def check_password(account = %__MODULE__{}, pass),
    do: Bcrypt.checkpw(pass, account.password)
  def check_password(nil, pass) do
    Bcrypt.checkpw(pass, @default_pass_for_timing_attacks)

    false
  end

  @spec generic_validations(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp generic_validations(changeset) do
    changeset
    |> validate_required([:email, :username, :password])
    |> validate_length(:password, min: 8)
    |> validate_change(:email, &validate_email/2)
    |> validate_change(:username, &validate_username/2)
    |> unique_constraint(:email)
    |> unique_constraint(:username)
  end

  @spec prepare_changes(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp prepare_changes(changeset) do
    changeset
    |> put_display_name()
    |> update_change(:email, &String.downcase/1)
    |> update_change(:username, &String.downcase/1)
    |> update_change(:password, &Bcrypt.hashpwsalt/1)
  end

  @spec put_display_name(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_display_name(changeset) do
    case fetch_change(changeset, :username) do
      {:ok, username} ->
        put_change(changeset, :display_name, username)
      :error ->
        changeset
    end
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
    || [email: "has invalid format"]
  end

  @spec validate_username(:username, String.t) :: [] | [username: String.t]
  docp """
  Validates that the username contains just alphanumeric and `!?$%-_.`
  characters.
  """
  defp validate_username(:username, value) do
    is_binary(value)
    && Regex.match?(~r/^[a-zA-Z0-9][a-zA-Z0-9\!\?\$\%\-\_\.]{1,14}$/, value)
    && []
    || [username: "has invalid format"]
  end

  defmodule Query do

    alias Helix.Account.Model.Account

    import Ecto.Query, only: [where: 3]

    @spec by_id(Account.id) :: Ecto.Queryable.t
    @spec by_id(Ecto.Queryable.t, Account.id) :: Ecto.Queryable.t
    def by_id(query \\ Account, account_id),
      do: where(query, [a], a.account_id == ^account_id)

    @spec by_email(Account.email) :: Ecto.Queryable.t
    @spec by_email(Ecto.Queryable.t, Account.email) :: Ecto.Queryable.t
    def by_email(query \\ Account, email) do
      email = String.downcase(email)

      where(query, [a], a.email == ^email)
    end

    @spec by_username(Account.username) :: Ecto.Queryable.t
    @spec by_username(Ecto.Queryable.t, Account.username) :: Ecto.Queryable.t
    def by_username(query \\ Account, username) do
      username = String.downcase(username)

      where(query, [a], a.username == ^username)
    end
  end
end
