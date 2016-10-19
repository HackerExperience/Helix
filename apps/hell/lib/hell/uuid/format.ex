defmodule HELL.UUID.Format do

  defstruct data: nil, errors: nil, valid?: true

  @validation_regex ~r/^[0-9A-F]+$/i

  @doc """
  Validates data.
  """
  def validate(data) do
    %__MODULE__{data: data}
    |> validate_length(:domain, max: 2, min: 2)
    |> validate_hex()
  end

  @doc """
  Joins UUID format into a string, throws {:uuid_format_error, _} on failures.
  """
  def join!(format) do
    if format.valid? do
      format.data
      |> Enum.map_join(fn {_, v} -> String.downcase(v) end)
    else
      throw {:uuid_format_error, format.errors}
    end
  end

  @doc """
  Validates length of UUID component.
  """
  defp validate_length(format, key, params) do
    if format.valid? do
      max = Keyword.get(params, :max, 0)
      min = Keyword.get(params, :min, 0)

      string = Map.fetch!(format.data, key)
      length = String.length(string)

      with true <- max == 0 or length <= max,
           true <- min == 0 or length >= min do
        format
      else
        false when length > max -> put_error(format, :max_length)
        false when length < min -> put_error(format, :min_length)
      end
    else
      format
    end
  end

  @doc """
  Validates that every UUID component is hexadecimal.
  """
  defp validate_hex(format) do
    if format.valid? do
      is_valid = format.data
        |> Enum.reduce_while(true, fn {k, v}, _acc ->
          if v == "" or Regex.match?(@validation_regex, v) do
            {:cont, true}
          else
            {:halt, {false, k}}
          end
        end)
      case is_valid do
        true -> format
        {false, key} -> put_error(format, {:invalid_hex, key})
      end
    else
      format
    end
  end

  @docp """
  Adds an error to UUID format.
  """
  defp put_error(data, error) do
    data
    |> Map.put(:valid?, false)
    |> Map.put(:errors, error)
  end
end
