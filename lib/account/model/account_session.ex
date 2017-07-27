defmodule Helix.Account.Model.AccountSession do

  use Ecto.Schema

  import Ecto.Changeset

  alias Ecto.Changeset
  alias HELL.PK
  alias Helix.Account.Model.Account

  @type t :: %__MODULE__{}
  @type token :: String.t
  @type id :: String.t

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

  @spec create_changeset(Account.t) ::
    Changeset.t
  def create_changeset(account) do
    %__MODULE__{}
    |> change()
    |> put_assoc(:account, account)
  end

  defmodule Query do
    import Ecto.Query, only: [where: 3]

    alias Ecto.Queryable
    alias Helix.Account.Model.AccountSession

    @spec by_session(Queryable.t, AccountSession.t | AccountSession.id) ::
      Queryable.t
    def by_session(query \\ AccountSession, session_or_session_id)
    def by_session(query, %AccountSession{session_id: session_id}),
      do: by_session(query, session_id)
    def by_session(query, session_id),
      do: where(query, [as], as.session_id == ^session_id)
  end
end
