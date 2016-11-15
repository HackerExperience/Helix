defmodule HELM.Account.Model.Account do
  use Ecto.Schema

  alias HELL.IPv6
  alias Comeonin.Bcrypt, as: Crypt
  alias Ecto.Changeset
  import Ecto.Changeset

  alias HELM.Account.Model.Account, as: MdlAccount

  @type t :: %__MODULE__{}
  @type create_params :: %{email: String.t, password: String.t, confirmation: String.t}
  @type update_params :: %{:email => String.t, optional(:password) => String.t, optional(:confirmed) => boolean}

  @primary_key {:account_id, EctoNetwork.INET, autogenerate: false}
  @derive {Poison.Encoder, only: [:email, :account_id]}

  schema "accounts" do
    field :email, :string
    field :confirmed, :boolean, default: false
    field :password, :string
    field :password_confirmation, :string, virtual: true

    timestamps
  end

  @creation_fields ~w(email password password_confirmation)
  @update_fields ~w(email password confirmed)

  @spec create_changeset(params :: create_params) :: Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> unique_constraint(:email, name: :unique_account_email)
    |> generic_validations()
    |> prepare_changes()
    |> put_primary_key()
  end

  @spec update_changeset(schema :: t, params :: update_params) :: Changeset.t
  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> generic_validations()
    |> prepare_changes()
  end

  @spec put_primary_key(changeset :: Changeset.t) :: Changeset.t
  defp put_primary_key(changeset) do
    ip = IPv6.generate([0x0000, 0x0000, 0x0000])

    changeset
    |> cast(%{account_id: ip}, ~w(account_id))
  end

  @spec generic_validations(changeset :: Changeset.t) :: Changeset.t
  defp generic_validations(changeset) do
    changeset
    |> validate_required(:email)
    |> validate_required(:password)
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password, required: true)
  end

  @spec prepare_changes(changeset :: Ecto.Changeset.t) :: Ecto.Changeset.t
  defp prepare_changes(changeset) do
    changeset
    |> update_change(:email, &String.downcase/1)
    |> update_change(:password, &Crypt.hashpwsalt/1)
  end
end