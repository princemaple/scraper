defmodule Scraper.Worker do
  use GenServer, restart: :temporary

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
        %{link_selectors: link_selectors, data_selectors: data_selectors} = state
      ) do
    case HTTPoison.get(state.link.url, [], follow_redirect: true) do
      {:ok, %{body: body}} ->
        parsed_html = Floki.parse(body)

        if state.link.depth < state.max_depth do
          links = Floki.attribute(parsed_html, "a", "href")

          Enum.each(
            Scraper.Link.select(links, link_selectors, state.link),
            &Scraper.Scheduler.schedule(state.scraper_id, &1)
          )
        end

        data = Scraper.Data.select(parsed_html, data_selectors)

        Enum.each(data, fn piece ->
          state.data_store.put(
            {:via, Registry, {state.scraper_id, :data_store}},
            piece
          )
        end)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error(inspect(reason))
    end

    {:stop, :shutdown, state}
  end
end
