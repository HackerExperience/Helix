defmodule Helix.Process.Controller.TableOfProcesses.ServerResources do

  defstruct [:cpu, :ram, :net]

  @type t :: %__MODULE__{
    cpu: non_neg_integer,
    ram: non_neg_integer,
    net: %{optional(HELL.PK.t) => %{dlk: non_neg_integer, ulk: non_neg_integer}}
  }
end