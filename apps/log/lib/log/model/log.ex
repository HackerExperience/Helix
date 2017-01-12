defmodule Helix.Log.Model.Log do

  use Ecto.Schema

  alias HELL.PK
  alias Helix.Log.Model.Revision

  import Ecto.Changeset

  @type t :: %__MODULE__{
    log_id: PK.t,
    server_id: PK.t,
    player_id: PK.t,
    message: String.t,
    crypto_version: non_neg_integer | nil,
    revisions: [Revision.t],
    inserted_at: NaiveDateTime.t,
    updated_at: NaiveDateTime.t
  }

  @type creation_params :: %{
    :server_id => PK.t,
    :player_id => PK.t,
    :message => String.t,
    optional(:crypto_version) => non_neg_integer,
    optional(:forge_version) => non_neg_integer
  }

  @type update_params :: %{
    optional(:crypto_version) => non_neg_integer,
    optional(:message) => non_neg_integer
  }

  @creation_fields ~w/server_id player_id message/a
  @update_fields ~w/message crypto_version/a

  @required_fields ~w/server_id player_id message/a

  @primary_key false
  schema "logs" do
    field :log_id, PK,
      primary_key: true

    field :server_id, PK
    field :player_id, PK

    field :message, :string
    field :crypto_version, :integer

    has_many :revisions, Revision,
      foreign_key: :log_id,
      references: :log_id,
      on_delete: :delete_all,
      on_replace: :delete

    timestamps()
  end

  @spec create_changeset(creation_params) :: Ecto.Changeset.t
  def create_changeset(params) do
    %__MODULE__{}
    |> cast(params, @creation_fields)
    |> validate_required(@required_fields)
    |> put_primary_key()
    |> prepare_changes(fn changeset ->
      revisions = [
        %{
          log_id: get_field(changeset, :log_id),
          player_id: params[:player_id],
          message: params[:message],
          forge_version: params[:forge_version]
        }
      ]

      changeset
      |> cast(%{revisions: revisions}, [])
      |> cast_assoc(:revisions, with: fn _, params ->
        Revision.create_changeset(params)
      end)
    end)
  end

  @spec update_changeset(t | Ecto.Changeset.t, update_params) :: Ecto.Changeset.t
  def update_changeset(struct, params) do
    struct
    |> cast(params, @update_fields)
    |> validate_required(@required_fields)
    |> validate_number(:crypto_version, greater_than: 0)
  end

  @spec put_primary_key(Ecto.Changeset.t) :: Ecto.Changeset.t
  defp put_primary_key(changeset) do
    if get_field(changeset, :log_id) do
      changeset
    else
      pk = PK.generate([])
      cast(changeset, %{log_id: pk}, [:log_id])
    end
  end
end