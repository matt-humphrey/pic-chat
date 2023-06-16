defmodule PicChat.Workers.DailySummaryEmail do
  # We've made max_attempts: 1 to avoid re-sending users the same email.
  use Oban.Worker, queue: :default, max_attempts: 1

  @impl true
  def perform(_params) do
    PicChat.SummaryEmail.send_to_subscribers()

    :ok
  end
end
