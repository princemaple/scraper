defmodule Scraper do
  def start_link(scraper_id, entries \\ [], opts \\ []) do
    with {:ok, pid} <-
           [scraper_id: scraper_id]
           |> Enum.into(opts)
           |> Scraper.Supervisor.start_link() do
      Enum.each(entries, &Scraper.Scheduler.schedule(scraper_id, &1))
      {:ok, pid}
    end
  end
end
