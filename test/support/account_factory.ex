defmodule Helix.Account.Factory do

  alias HELL.TestHelper.Random
  alias Helix.Account.Model.Account
  alias Helix.Account.Model.AccountSetting

  alias Helix.Account.Repo

  @type thing :: :account | :account_setting

  @spec changeset(thing, map | Keyword.t) ::
    Ecto.Changeset.t
  def changeset(thing, params \\ %{}) do
    attrs =
      thing
      |> params_for()
      |> Map.merge(to_map(params))

    fabricate_changeset(thing, attrs)
  end

  @spec changeset_list(pos_integer, thing, map | Keyword.t) ::
    [Ecto.Changeset.t, ...]
  def changeset_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: changeset(thing, params)
  end

  @spec build(thing, map | Keyword.t) ::
    Ecto.Schema.t
  def build(thing, params \\ %{}) do
    thing
    |> changeset(params)
    |> ensure_valid_changeset()
    |> Ecto.Changeset.apply_changes()
  end

  @spec build_list(pos_integer, thing, map | Keyword.t) ::
    [Ecto.Schema.t, ...]
  def build_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: build(thing, params)
  end

  @spec insert(thing, map | Keyword.t) ::
    Ecto.Schema.t
  def insert(thing, params \\ %{}) do
    thing
    |> changeset(params)
    |> Repo.insert!()
  end

  @spec insert_list(pos_integer, thing, map | Keyword.t) ::
    [Ecto.Schema.t, ...]
  def insert_list(n, thing, params \\ %{}) when n >= 1 do
    for _ <- 1..n,
      do: insert(thing, params)
  end

  @spec params_for(thing) ::
    map
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
      account: changeset(:account),
      settings: settings
    }
  end

  @spec fabricate_changeset(thing, map) ::
    Ecto.Changeset.t
  defp fabricate_changeset(:account, params) do
    Account.create_changeset(params)
  end

  defp fabricate_changeset(:account_setting, params = %{account_id: _}),
    do: AccountSetting.changeset(params)
  defp fabricate_changeset(:account_setting, params) do
    params
    |> Map.put(:account_id, Random.pk())
    |> AccountSetting.changeset()
    # HACK: Right now AccountSetting is requiring account_id and we don't want
    #   to insert the account to generate the setting, right ?
    |> Ecto.Changeset.delete_change(:account_id)
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
