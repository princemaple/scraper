defmodule Scraper do
  def start_link(scraper_id, entries \\ [], opts \\ []) do
    on_start =
      [scraper_id: scraper_id]
      |> Enum.into(opts)
      |> Scraper.Supervisor.start_link()

    Enum.each(entries, &Scraper.Scheduler.schedule(scraper_id, &1))

    on_start
  end
end
