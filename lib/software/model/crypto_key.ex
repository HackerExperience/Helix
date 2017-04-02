defmodule Helix.Software.Model.CryptoKey do

  use Ecto.Schema

  alias Helix.Software.Model.File
  alias Helix.Software.Model.Storage

  import Ecto.Changeset

  @type t :: %__MODULE__{
    file_id: HELL.PK.t,
    target_file_id: HELL.PK.t | nil,
    target_server_id: HELL.PK.t
  }

  @default_path "/.keys"
  @software_type :crypto_key

  @primary_key false
  schema "crypto_keys" do
    field :file_id, HELL.PK,
      primary_key: true

    field :target_file_id, HELL.PK
    field :target_server_id, HELL.PK

    belongs_to :file, File,
      foreign_key: :file_id,
      references: :file_id,
      define_field: false

    belongs_to :target_file, File,
      foreign_key: :target_file_id,
      references: :file_id,
      define_field: false
  end

  @spec create(Storage.t, HELL.PK.t, File.t) :: Ecto.Changeset.t
  @doc """
  Creates a key for `target_file` on `storage`.

  `server_id` is the server that has `target_file` so we can inform the player
  that the key is for a certain server in their hacked database
  """
  def create(storage = %Storage{}, server_id, target_file = %File{}) do
    file = generate_file(storage)

    %__MODULE__{}
    |> cast(%{target_server_id: server_id}, [:target_server_id])
    |> put_assoc(:target_file, target_file, required: true)
    |> put_assoc(:file, file, required: true)
    |> validate_required([:target_server_id])
  end

  defp generate_file(storage) do
    params = %{
      # FIXME: Use an apropriate
      name: "Key #{Enum.random(1..100_000_000)}",
      path: @default_path,
      # REVIEW: Make keys actually have a size? If so we'd have to check if the
      #   storage can store them tho
      file_size: 1,
      software_type: @software_type,
    }

    File.create(storage, params)
  end

  defmodule Query do

    alias Ecto.Queryable

    alias Helix.Software.Model.CryptoKey
    alias Helix.Software.Model.File
    alias Helix.Software.Model.Storage

    import Ecto.Query, only: [join: 5, where: 3]

    @spec from_storage(Queryable.t, Storage.t) :: Queryable.t
    def from_storage(query \\ CryptoKey, %Storage{storage_id: id}) do
      query
      |> join(:inner, [k], f in File, k.file_id == f.file_id)
      |> where([k, ..., f], f.storage_id == ^id)
    end

    @spec target_files_on_storage(Queryable.t, Storage.t) :: Queryable.t
    def target_files_on_storage(query \\ CryptoKey, %Storage{storage_id: id}) do
      query
      |> join(:inner, [k], t in File, k.target_file_id == t.file_id)
      |> where([k, ..., t], t.storage_id == ^id)
    end

    @spec target_file(Queryable.t, File.t) :: Queryable.t
    def target_file(query \\ CryptoKey, %File{file_id: id}),
      do: where(query, [k], k.target_file_id == ^id)
  end
end
