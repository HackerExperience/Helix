defmodule Helix.Entity.Public.Index.Database do

  alias HELL.ClientUtils
  alias HELL.HETypes
  alias Helix.Software.Model.Virus
  alias Helix.Software.Public.Index, as: SoftwareIndex
  alias Helix.Software.Query.File, as: FileQuery
  alias Helix.Software.Query.Virus, as: VirusQuery
  alias Helix.Entity.Model.Database
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Query.Database, as: DatabaseQuery

  @type index ::
    %{
      entity_id: Entity.id,
      bank_accounts: [Database.BankAccount.t],
      servers: [Database.Server.t]
    }

  @type rendered_index ::
    %{
      bank_accounts: [rendered_bank_account],
      servers: [rendered_server],
    }

  @typep rendered_bank_account ::
    %{
      atm_id: String.t,
      atm_ip: String.t,
      account_number: pos_integer,
      password: String.t | nil,
      token: String.t | nil,
      notes: String.t | nil,
      known_balance: non_neg_integer | nil,
      last_login_date: DateTime.t | nil,
      last_update: HETypes.client_timestamp
    }

  @typep rendered_server ::
    %{
      network_id: String.t,
      ip: String.t,
      type: String.t,
      password: String.t | nil,
      alias: String.t | nil,
      notes: String.t | nil,
      viruses: [rendered_virus],
      last_update: HETypes.client_timestamp
    }

  @typep rendered_virus ::
    %{
      file_id: String.t,
      name: String.t,
      version: float,
      type: String.t,
      extension: String.t,
      running_time: seconds :: integer | nil,
      is_active: boolean
    }

  @spec index(Entity.t) ::
    index
  def index(entity) do
    entity
    |> DatabaseQuery.get_database()
    |> Map.merge(%{entity_id: entity.entity_id})
  end

  @spec render_index(index) ::
    rendered_index
  def render_index(index) do
    # `entity_viruses` is used as a cache to fetch all viruses in a single query
    entity_viruses = VirusQuery.list_by_entity(index.entity_id)

    rendered_servers =
        Enum.map(index.servers, fn server_entry ->
          render_server(server_entry, entity_viruses)
        end)

    %{
      bank_accounts: Enum.map(index.bank_accounts, &render_bank_account/1),
      servers: rendered_servers
    }
  end

  @spec render_bank_account(Database.BankAccount.t) ::
    rendered_bank_account
  defp render_bank_account(entry = %Database.BankAccount{}) do
    last_login_date =
      if is_map(entry.last_login_date) do
        ClientUtils.to_timestamp(entry.last_login_date)
      else
        nil
      end

    %{
      atm_id: to_string(entry.atm_id),
      atm_ip: to_string(entry.atm_ip),
      account_number: entry.account_number,
      password: entry.password,
      token: entry.token,
      notes: entry.notes,
      known_balance: entry.known_balance,
      last_login_date: last_login_date,
      last_update: ClientUtils.to_timestamp(entry.last_update)
    }
  end

  @spec render_server(Database.Server.t, [Virus.t]) ::
    rendered_server
  defp render_server(entry = %Database.Server{}, entity_viruses) do
    rendered_viruses =
      Enum.map(entry.viruses, fn virus_entry ->
        render_virus(virus_entry, entity_viruses)
      end)

    %{
      network_id: to_string(entry.network_id),
      ip: to_string(entry.server_ip),
      type: to_string(entry.server_type),
      password: entry.password,
      alias: entry.alias,
      notes: entry.notes,
      viruses: rendered_viruses,
      last_update: ClientUtils.to_timestamp(entry.last_update)
    }
  end

  @spec render_virus(Database.Virus.t, [Virus.t]) ::
    rendered_virus
  defp render_virus(entry = %Database.Virus{}, entity_viruses) do
    virus = Enum.find(entity_viruses, &(&1.file_id == entry.file_id))

    # OPTIMIZE: The query below should be replaced by a cache within either
    # `Database.Virus` or `Software.Virus`
    rendered_file =
      entry.file_id
      |> FileQuery.fetch()
      |> SoftwareIndex.render_file()

    %{
      file_id: to_string(virus.file_id),
      name: rendered_file.name,
      version: rendered_file.version,
      type: rendered_file.type,
      extension: rendered_file.extension,
      running_time: virus.running_time,
      is_active: virus.is_active?
    }
  end
end
