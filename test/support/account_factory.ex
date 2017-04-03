defmodule Helix.Account.Factory do

  alias HELL.TestHelper.Random
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting

  alias Helix.Account.Repo

  @spec build_changeset(atom, map() | Keyword.t) ::
    Ecto.Changeset.t
  def build_changeset(thing, params \\ %{}) do
    attrs =
      thing
      |> params_for()
      |> Map.merge(to_map(params))

    generate_changeset(thing, attrs)
  end

  @spec build_changeset_list(pos_integer, atom, map() | Keyword.t) ::
    [Ecto.Changeset.t, ...]
  def build_changeset_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: build_changeset(thing, params)
  end

  @spec build(atom, map() | Keyword.t) ::
    Ecto.Schema.t
  def build(thing, params \\ %{}) do
    thing
    |> build_changeset(params)
    |> ensure_valid_changeset()
    |> Ecto.Changeset.apply_changes()
  end

  @spec build_list(atom, map() | Keyword.t) ::
    [Ecto.Schema.t, ...]
  def build_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: build(thing, params)
  end

  @spec insert(atom, map() | Keyword.t) ::
    Ecto.Schema.t
  def insert(thing, params \\ %{}) do
    thing
    |> build(params)
    |> Repo.insert!()
  end

  @spec insert_list(atom, map() | Keyword.t) ::
    [Ecto.Schema.t, ...]
  def insert_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: insert(thing, params)
  end

  defp params_for(:account) do
    %{
      username: Random.username(),
      email: Burette.Internet.email(),
      password: Burette.Internet.password()
    }
  end

  defp params_for(:account_setting) do
    settings = %{
      is_beta: true
    }

    %{
      account: build(:account),
      settings: settings
    }
  end

  defp generate_changeset(:account, params) do
    Account.create_changeset(params)
  end

  defp generate_changeset(:account_setting, params = %{account_id: _}),
    do: AccountSetting.changeset(params)
  defp generate_changeset(:account_setting, params) do
    params
    |> Map.put(:account_id, params.account.account_id)
    |> AccountSetting.changeset()
    |> Ecto.Changeset.put_assoc(:account, params.account)
  end

  defp to_map(x = %{}),
    do: x
  defp to_map(x) when is_list(x),
    do: :maps.from_list(x)

  defp ensure_valid_changeset(cs = %Ecto.Changeset{valid?: true}),
    do: cs
  defp ensure_valid_changeset(cs),
    do: raise "invalid changeset generated on factory: #{inspect cs}"
end
