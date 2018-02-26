import Helix.Balance

balance Software.Constant do
  @moduledoc """
  Software-related constants.
  """

  alias Helix.Software.Model.Software

  @spec ratio(Software.module_name) :: float

  @doc """
  `ratio` is one of the most fundamental balance constants in the game. It
  defines a ratio between software types. This ratio is used to figure out the
  resulting file size, cost to further develop it, among other things.

  The software `ratio` is actually defined according to each module, so for
  instance a Cracker has one ratio for `bruteforce` and a different one for
  `overflow`.

  In fact, the `bruteforce` module of the Cracker is considered the most
  important module of the game and as such it's been normalized. All other
  ratios are defined as a fraction of `bruteforce`.
  """
  # Cracker
  constant :ratio, :bruteforce, 1
  constant :ratio, :overflow, 0.9

  # Hasher
  constant :ratio, :password, 0.95

  # Firewall
  constant :ratio, :fwl_passive, 0.9
  constant :ratio, :fwl_active, 0.8

  # LogForger
  constant :ratio, :log_edit, 0.7
  constant :ratio, :log_create, 0.6

  # LogRecover
  constant :ratio, :log_recover, 0.65

  # Spyware
  constant :ratio, :vir_spyware, 0.5
end
