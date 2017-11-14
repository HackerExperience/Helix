defmodule Helix.Maroto do
  @moduledoc """
  Use Helix.Maroto and smile!

  (Sorriso maroto)
  """

  defmacro __using__(_) do
    quote do
      unquote(marote_aliases())
      unquote(marote_helpers())

      use Helix.Maroto.Functions

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
      alias Helix.Test.Story.Setup, as: StorySetup
      alias Helix.Test.Universe.Bank.Setup, as: BankSetup
      alias Helix.Test.Universe.NPC.Setup, as: NPCSetup

    end
  end

  defp marote_helpers do

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

defmodule Helix.Maroto.Functions do

  alias Helix.Account.Action.Flow.Account, as: AccountFlow

  alias HELL.TestHelper.Random

  defmacro __using__(_) do
    quote do

      import Helix.Maroto.Functions
    end
  end

  @doc """
  Opts:

  - email: email
  - user: Username.
  - pass: Password.
  """
  def create_account(opts \\ []) do
    email = Keyword.get(opts, :email, Random.email())
    user = Keyword.get(opts, :user, Random.username())
    pass = Keyword.get(opts, :pass, Random.string(min: 8, max: 10))

    related = %{email: email, user: user, pass: pass}

    {:ok, account} = AccountFlow.create(email, user, pass)

    {account, related}
  end
end
