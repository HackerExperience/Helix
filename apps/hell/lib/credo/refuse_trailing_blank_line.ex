defmodule Credo.Check.Readability.RefuseTrailingBlankLine do
  @moduledoc """
  Files should NOT end in a trailing blank line.
  """

  @explanation [check: @moduledoc]

  use Credo.Check, base_priority: :low

  def run(%SourceFile{lines: lines} = source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    {line_no, last_line} = List.last(lines)
    if String.strip(last_line) == "" do
      [issue_for(issue_meta, line_no)]
    else
      []
    end
  end

  def issue_for(issue_meta, line_no) do
    format_issue issue_meta,
      message: "There should NOT be a final \\n at the end of each file.",
      line_no: line_no
  end
end