defmodule HELM.Account.Model.Accounts do
  use Ecto.Schema

  alias Comeonin.Bcrypt, as: Crypt
  import Ecto.Changeset

  @primary_key {:account_id, :string, autogenerate: false}
  @derive {Poison.Encoder, only: [:email, :account_id]}

  schema "accounts" do
    field :email, :string
    field :confirmed, :boolean, default: false
    field :password, :string
    field :password_confirmation, :string, virtual: true

    timestamps
  end

  @creation_fields ~w(email password password_confirmation)
  @update_fields ~w(email password confirmation)

  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(:password_confirmation)
    |> validate_confirmation(:password)
    |> update_change(:email, &String.downcase/1)
    |> unique_constraint(:email, name: :unique_account_email)
    |> generic_validations()
    |> put_uuid()
  end

  def update_changeset(schema, params) do
    schema
    |> cast(params, @update_fields)
    |> generic_validations()
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: Ecto.Changeset.put_change(changeset, :account_id, HELL.ID.generate("ACCT")),
      else: changeset
  end

  defp generic_validations(changeset) do
    changeset
    |> validate_required(:email)
    |> validate_required(:password)
    |> validate_length(:password, min: 8)
    |> update_change(:password, &Crypt.hashpwsalt/1)
  end
end