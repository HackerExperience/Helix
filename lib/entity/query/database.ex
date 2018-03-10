defmodule Helix.Entity.Query.Database do
  @moduledoc """
  API to query the Hacked Database.

  Note that, per definition, the data stored at the Hacked Database may be
  outdated/invalid. It is a snapshot of the player's hack knowledge on a given
  time.
  """

  alias HELL.IPv4
  alias Helix.Network.Model.Network
  alias Helix.Universe.Bank.Model.BankAccount
  alias Helix.Entity.Internal.Database, as: DatabaseInternal
  alias Helix.Entity.Model.Entity
  alias Helix.Entity.Model.Database

  @spec fetch_server(Entity.idt, Network.idt, IPv4.t) ::
    Database.Server.t
    | nil
  @doc """
  Returns the entry corresponding to the given server (nip).
  """
  defdelegate fetch_server(entity, network, server_ip),
    to: DatabaseInternal

  @spec fetch_bank_account(Entity.idt, BankAccount.t) ::
    Database.BankAccount.t
    | nil
  @doc """
  Returns the entry corresponding to the given bank account. May be outdated.
  """
  defdelegate fetch_bank_account(entity, account),
    to: DatabaseInternal

  @spec get_database(Entity.t) ::
    DatabaseInternal.full_database
  @doc """
  Returns the entire Hacked Database. The format is defined at
  `DatabaseInternal.full_database`
  """
  defdelegate get_database(entity),
    to: DatabaseInternal

  @spec get_server_password(Entity.t, Network.idt, IPv4.t) ::
    String.t
    | nil
  @doc """
  Returns the stored password for that server. It may be outdated or empty.
  """
  def get_server_password(entity, network, server_ip) do
    with entry = %{} <- fetch_server(entity, network, server_ip) do
      entry.password
    end
  end
end
