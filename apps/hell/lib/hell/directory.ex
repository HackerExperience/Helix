defmodule HELL.Directory do
  @moduledoc """
  Represents an UNIX style directory path

  Internally stores it as an encoded ltree path. Represents it to Ecto as an
  struct to raise when a string comparison is tried. A `to_string`
  implementation is provided though to allow such checks (note that it is not
  particularly optimized)

  This encoding step is done to allow storing labels even with unallowed
  characters.

  ## Example

      iex> HELL.Directory.cast("/home/my-user/My Documents (not really, lol)/100%/.pass")
      {:ok,
        %HELL.Directory{path: "NBXW2ZI.NV4S25LTMVZA.JV4SARDPMN2W2ZLOORZSAKDON52CA4TFMFWGY6JMEBWG63BJ.GEYDAJI.FZYGC43T"}}

      iex> to_string(HELL.Directory.cast("/home/my-user/My Documents (not really, lol)/100%/.pass") |> elem(1))
      "/home/my-user/My Documents (not really, lol)/100%/.pass"
  """

  @behaviour Ecto.Type

  @opaque t :: %__MODULE__{}

  @typep path :: String.t
  @typep label :: String.t
  @typep directory :: String.t

  defstruct [:path]

  def type,
    do: :ltree

  def cast(str) when is_binary(str),
    do: {:ok, convert_to_ltree(str)}
  def cast(_),
    do: :error

  def load(str) when is_binary(str),
    do: {:ok, %__MODULE__{path: str}}

  def dump(%__MODULE__{path: str}),
    do: {:ok, str}
  def dump(_),
    do: :error

  @spec convert_to_ltree(path) :: t
  defp convert_to_ltree(""),
    do: represent_path("")
  defp convert_to_ltree("/"),
    do: represent_path("")
  defp convert_to_ltree(path) when is_binary(path),
    do: convert_to_ltree(path, "", "")

  @spec convert_to_ltree(path, path, directory) :: t
  defp convert_to_ltree("/", acc, cwd),
    do: represent_path(merge_cwd(acc, cwd))
  defp convert_to_ltree("", acc, cwd),
    do: represent_path(merge_cwd(acc, cwd))
  defp convert_to_ltree("/" <> rest, acc, cwd),
    do: convert_to_ltree(rest, merge_cwd(acc, cwd), "")
  defp convert_to_ltree(<<char::utf8, rest::binary>>, acc, cwd),
    do: convert_to_ltree(rest, acc, cwd <> <<char::utf8>>)

  @spec merge_cwd(path, directory) :: path
  defp merge_cwd("", cwd),
    do: cwd_to_label(cwd)
  defp merge_cwd(acc, cwd),
    do: acc <> "." <> cwd_to_label(cwd)

  @spec cwd_to_label(directory) :: label
  defp cwd_to_label(cwd),
    do: Base.encode32(cwd, padding: false)

  @spec represent_path(path) :: t
  defp represent_path(path),
    do: %__MODULE__{path: path}
end

defimpl String.Chars, for: HELL.Directory do
  def to_string(%HELL.Directory{path: path}) do
    abs_path =
      path
      |> String.split(".")
      |> Enum.map(&Base.decode32!(&1, padding: false))
      |> Enum.join("/")

    "/" <> abs_path
  end
end
