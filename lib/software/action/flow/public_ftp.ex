defmodule Helix.Software.Action.Flow.PublicFTP do

  import HELF.Flow

  alias Helix.Event
  alias Helix.Server.Model.Server
  alias Helix.Software.Action.PublicFTP, as: PublicFTPAction
  alias Helix.Software.Model.File
  alias Helix.Software.Model.PublicFTP

  @spec enable_server(Server.t) ::
    {:ok, PublicFTP.t}
    | {:error, {:pftp, :already_enabled}}
  @doc """
  Enables a PublicFTP server, emitting any relevant events.
  """
  def enable_server(server = %Server{}) do
    flowing do
      with \
        {:ok, pftp, events} <- PublicFTPAction.enable_server(server),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, pftp}
      end
    end
  end

  @spec disable_server(PublicFTP.t) ::
    {:ok, PublicFTP.t}
    | {:error, :internal}
  @doc """
  Disables a PublicFTP server, emitting any relevant events.
  """
  def disable_server(pftp = %PublicFTP{}) do
    flowing do
      with \
        {:ok, pftp, events} <- PublicFTPAction.disable_server(pftp),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, pftp}
      end
    end
  end

  @spec add_file(PublicFTP.t, File.t) ::
    {:ok, PublicFTP.File.t}
    | {:error, :internal}
  def add_file(pftp = %PublicFTP{}, file = %File{}) do
    flowing do
      with \
        {:ok, pftp_file, events} <- PublicFTPAction.add_file(pftp, file),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, pftp_file}
      end
    end
  end

  @spec remove_file(PublicFTP.t, PublicFTP.File.t) ::
    {:ok, PublicFTP.File.t}
    | {:error, :internal}
  def remove_file(pftp = %PublicFTP{}, pftp_file = %PublicFTP.File{}) do
    flowing do
      with \
        {:ok, pftp_file, events} <-
          PublicFTPAction.remove_file(pftp, pftp_file),
        on_success(fn -> Event.emit(events) end)
      do
        {:ok, pftp_file}
      end
    end
  end
end
