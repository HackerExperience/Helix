defmodule HELM.Account.Model do
  use Ecto.Schema
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
    |> generic_validations()
    |> put_uuid()
  end

  def update_changeset(model, params) do
    model
    |> cast(params, @update_fields)
    |> generic_validations()
  end

  defp put_uuid(changeset) do
    if changeset.valid?,
      do: Ecto.Changeset.put_change(changeset, :account_id, HELL.ID.generate("ACCNT")),
      else: changeset
  end

  defp generic_validations(changeset) do
    changeset
    |> validate_required(:email)
    |> validate_required(:password)
    |> validate_length(:password, min: 8)
  end
end
