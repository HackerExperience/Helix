defmodule Helix.Test.IntegrationCase do

  use ExUnit.CaseTemplate

  using do
    quote do
      @moduletag :integration

      setup do
        repos = Application.get_env(:helix, :ecto_repos)
        Enum.each(repos, fn repo ->
          :ok = Ecto.Adapters.SQL.Sandbox.checkout(repo)

          Ecto.Adapters.SQL.Sandbox.mode(repo, {:shared, self()})
        end)
      end
    end
  end
end
