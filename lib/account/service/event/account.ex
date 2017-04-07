defmodule Helix.Software.Service.Event.Account do

  alias HELF.Mailer
  alias Helix.Account.Model.Account.AccountCreatedEvent
  alias Helix.Account.Service.Flow.Account, as: AccountFlow

  @spec send_email(%AccountCreatedEvent{}) :: any
  def send_email(event = %AccountCreatedEvent{}) do
    # FIXME: write this email properly
    Mailer.new()
    |> Mailer.from("no-reply@hackerexperience.comp")
    |> Mailer.to(event.email)
    |> Mailer.subject("Welcome to Hacker Experience")
    |> Mailer.html("Lorem ipsum.")
    |> Mailer.text("Lorem ipsum.")
    |> Mailer.send()
  end

  @spec setup_account(%AccountCreatedEvent{}) :: any
  def setup_account(event = %AccountCreatedEvent{}),
    do: AccountFlow.setup(event.account_id)
end
