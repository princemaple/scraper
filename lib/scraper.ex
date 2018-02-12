defmodule Scraper do
  @spec start_link(
    scraper_id :: atom,
    entries :: String.t() | [String.t()],
    opts :: Keyword.t()
  ) :: GenServer.on_start()
  def start_link(scraper_id, entries \\ [], opts \\ []) do
    with {:ok, pid} <-
           [scraper_id: scraper_id]
           |> Enum.into(opts)
           |> Scraper.Supervisor.start_link() do
      entries
      |> List.wrap()
      |> Enum.each(&Scraper.Scheduler.schedule(scraper_id, &1))

      {:ok, pid}
    end
  end
end
