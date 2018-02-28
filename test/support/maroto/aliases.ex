defmodule Helix.Maroto.Aliases do

  defmacro __using__(_) do
    quote do

      unquote(marote_helix())
      unquote(marote_aliases())
      unquote(marote_helpers())
      unquote(marote_tools())

    end
  end

  defp marote_helix do
    quote do

      alias Helix.Event
      alias Helix.Core.Validator

      alias Helix.Account.Action.Flow.Account, as: AccountFlow
      alias Helix.Account.Model.Account
      alias Helix.Account.Public.Account, as: AccountPublic
      alias Helix.Account.Public.Index, as: AccountIndex
      alias Helix.Account.Query.Account, as: AccountQuery

      alias Helix.Cache.Action.Cache, as: CacheAction
      alias Helix.Cache.Query.Cache, as: CacheQuery

      alias Helix.Entity.Action.Database, as: DatabaseAction
      alias Helix.Entity.Action.Entity, as: EntityAction
      alias Helix.Entity.Model.Entity
      alias Helix.Entity.Query.Database, as: DatabaseQuery
      alias Helix.Entity.Query.Entity, as: EntityQuery

      alias Helix.Log.Model.Log
      alias Helix.Log.Public.Index, as: LogIndex
      alias Helix.Log.Query.Log, as: LogQuery

      alias Helix.Network.Action.Tunnel, as: TunnelAction
      alias Helix.Network.Action.DNS, as: DNSAction
      alias Helix.Network.Action.Flow.Tunnel, as: TunnelFlow
      alias Helix.Network.Model.Connection
      alias Helix.Network.Model.Link
      alias Helix.Network.Model.Network
      alias Helix.Network.Model.Tunnel
      alias Helix.Network.Query.DNS, as: DNSQuery
      alias Helix.Network.Query.Network, as: NetworkQuery
      alias Helix.Network.Query.Tunnel, as: TunnelQuery
      alias Helix.Network.Query.Web, as: WebQuery

      alias Helix.Process.Model.Process
      alias Helix.Process.Query.Process, as: ProcessQuery

      alias Helix.Server.Action.Flow.Server, as: ServerFlow
      alias Helix.Server.Model.Server
      alias Helix.Server.Query.Server, as: ServerQuery
      alias Helix.Server.Public.Index, as: ServerIndex
      alias Helix.Server.Public.Server, as: ServerPublic

      alias Helix.Software.Model.File
      alias Helix.Software.Model.Software
      alias Helix.Software.Public.File, as: FilePublic
      alias Helix.Software.Public.Index, as: SoftwareIndex
      alias Helix.Software.Query.File, as: FileQuery
      alias Helix.Software.Query.Storage, as: StorageQuery
      alias Helix.Software.Query.PublicFTP, as: PublicFTPQuery

      alias Helix.Story.Action.Story, as: StoryAction
      alias Helix.Story.Model.Step
      alias Helix.Story.Public.Story, as: StoryPublic
      alias Helix.Story.Query.Story, as: StoryQuery

      alias Helix.Universe.Bank.Action.Flow.BankAccount, as: BankAccountFlow
      alias Helix.Universe.Bank.Action.Flow.BankTransfer, as: BankTransferFlow
      alias Helix.Universe.Bank.Model.ATM
      alias Helix.Universe.Bank.Model.Bank
      alias Helix.Universe.Bank.Model.BankAccount
      alias Helix.Universe.Bank.Model.BankToken
      alias Helix.Universe.Bank.Model.BankTransfer
      alias Helix.Universe.Bank.Query.Bank, as: BankQuery

      alias Helix.Universe.NPC.Model.NPC
      alias Helix.Universe.NPC.Query.NPC, as: NPCQuery

    end
  end

  defp marote_aliases do
    quote do

      alias HELL.TestHelper.Random
      alias Helix.Test.Account.Setup, as: AccountSetup
      alias Helix.Test.Channel.Setup, as: ChannelSetup
      alias Helix.Test.Entity.Setup, as: EntitySetup
      alias Helix.Test.Event.Setup, as: EventSetup
      alias Helix.Test.Log.Setup, as: LogSetup
      alias Helix.Test.Network.Setup, as: NetworkSetup
      alias Helix.Test.Process.Setup, as: ProcessSetup
      alias Helix.Test.Server.Setup, as: ServerSetup
      alias Helix.Test.Software.Setup, as: SoftwareSetup
      alias Helix.Test.Software.Setup.PFTP, as: PFTPSetup
      alias Helix.Test.Story.Setup, as: StorySetup
      alias Helix.Test.Universe.Bank.Setup, as: BankSetup
      alias Helix.Test.Universe.NPC.Setup, as: NPCSetup

    end
  end

  defp marote_helpers do
    quote do

      alias Helix.Test.Account.Helper, as: AccountHelper
      alias Helix.Test.Channel.Helper, as: ChannelHelper
      alias Helix.Test.Entity.Helper, as: EntityHelper
      alias Helix.Test.Event.Helper, as: EventHelper
      alias Helix.Test.Log.Helper, as: LogHelper
      alias Helix.Test.Network.Helper, as: NetworkHelper
      alias Helix.Test.Process.Helper, as: ProcessHelper
      alias Helix.Test.Server.Helper, as: ServerHelper
      alias Helix.Test.Software.Helper, as: SoftwareHelper
      alias Helix.Test.Story.Helper, as: StoryHelper
      alias Helix.Test.Universe.Bank.Helper, as: BankHelper
      alias Helix.Test.Universe.NPC.Helper, as: NPCHelper

    end
  end

  defp marote_tools do
    quote do

      alias Helix.Maroto.Playstate
      alias Helix.Test.Channel.Interceptor

      Interceptor.start_link()

    end
  end
end
