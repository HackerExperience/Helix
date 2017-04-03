defmodule Helix.Event.Dispatcher do
  @moduledoc false

  use HELF.Event

  alias Helix.Software

  # TODO: This type belongs to HELF.Event
  @type t :: struct

  event Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent,
    Software.Service.Event.Encryptor,
    :complete

  event Software.Model.SoftwareType.Encryptor.ProcessConclusionEvent,
    IO,
    :inspect

  event Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent,
    Software.Service.Event.Decryptor,
    :complete
  event Software.Model.SoftwareType.Decryptor.ProcessConclusionEvent,
    IO,
    :inspect
end
