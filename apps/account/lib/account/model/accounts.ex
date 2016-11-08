defmodule HELM.Account.Model.Account do
  use Ecto.Schema

  alias HELL.IPv6
  alias Comeonin.Bcrypt, as: Crypt
  import Ecto.Changeset

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

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> unique_constraint(:email, name: :unique_account_email)
    |> generic_validations()
    |> prepare_changes()
    |> put_primary_key()
  end

  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> generic_validations()
    |> prepare_changes()
  end

  defp put_primary_key(changeset) do
    if changeset.valid? do
      ip = IPv6.generate([0x0000, 0x0000, 0x0000])

      changeset
      |> cast(%{account_id: ip}, ~w(account_id))
    else
      changeset
    end
  end

  defp generic_validations(changeset) do
    changeset
    |> validate_required(:email)
    |> validate_required(:password)
    |> validate_length(:password, min: 8)
    |> validate_confirmation(:password, required: true)
  end

  defp prepare_changes(changeset) do
    changeset
    |> update_change(:email, &String.downcase/1)
    |> update_change(:password, &Crypt.hashpwsalt/1)
  end
end