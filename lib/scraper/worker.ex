defmodule Scraper.Worker do
  use GenServer, restart: :temporary

  import Scraper, only: [via: 2]
  require Logger

  def start_link(state) do
    GenServer.start_link(__MODULE__, state)
  end

  def init(state) do
    Logger.debug("Working on #{state.link.url}")
    send(self(), :start)
    {:ok, state}
  end

  def handle_info(
        :start,
        %{
          link: link,
          max_depth: max_depth,
          scraper_id: scraper_id,
          link_selectors: link_selectors,
          data_selectors: data_selectors
        } = state
      ) do
    case HTTPoison.get(link.url, [], follow_redirect: true) do
      {:ok, %{body: body}} ->
        parsed_html = Floki.parse(body)

        if link.depth < max_depth do
          links = Floki.attribute(parsed_html, "a", "href")

          Enum.each(
            Scraper.Link.select(links, link_selectors, link),
            &Scraper.Scheduler.schedule(scraper_id, &1)
          )
        end

        data = Scraper.Data.select(parsed_html, data_selectors)
        Enum.each(data, &state.data_store.put(via(scraper_id, :data_store), &1))

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error(inspect(reason))
    end

    {:stop, :shutdown, state}
  end
end
