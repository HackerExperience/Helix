defmodule Helix.Test.Log.Helper do

  @doc """
  Given a log, returns the expected format of a public view.
  """
  def public_view(log_list) when is_list(log_list),
    do: Enum.map(log_list, &(public_view(&1)))
  def public_view(log) do
    %{
      log_id: log.log_id,
      message: List.first(log.revisions).message,
      inserted_at: log.inserted_at
    }
  end

  def random_message do
    "This is a random log message"
  end
end
