defmodule Helix.Account.Model.AccountSession do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Account.Model.Account

  import Ecto.Changeset

  @type t :: %__MODULE__{}

  @primary_key false
  @ecto_autogenerate {:session_id, {Ecto.UUID, :generate, []}}
  schema "account_sessions" do
    field :session_id, Ecto.UUID,
      primary_key: true

    field :account_id, PK

    belongs_to :account, Account,
      references: :account_id,
      foreign_key: :account_id,
      define_field: false

    timestamps()
  end

  def create(account) do
    %__MODULE__{}
    |> change()
    |> put_assoc(:account, account)
  end
end
