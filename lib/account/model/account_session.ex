defmodule Helix.Account.Model.AccountSession do

  use Ecto.Schema

  import Ecto.Changeset

  alias HELL.PK
  alias Helix.Account.Model.Account

  @type t :: %__MODULE__{}
  @type token :: String.t
  @type session :: String.t

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

  @spec create(Account.t) ::
    Ecto.Changeset.t
  def create(account) do
    %__MODULE__{}
    |> change()
    |> put_assoc(:account, account)
  end
end
