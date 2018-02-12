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

  def handle_info(:start, state) do
    case HTTPoison.get(state.link.url, [], follow_redirect: true) do
      {:ok, %{body: body}} ->
        html = Floki.parse(body)

        if state.link.depth < state.max_depth do
          links = Floki.attribute(html, "a", "href")
          Enum.each(Enum.reject(links, &match?("#" <> _rest, &1)), fn link ->
            Scraper.Scheduler.schedule(
              state.scraper_id,
              Scraper.Link.new(link, state.link)
            )
          end)
        end

        img_srcs = Floki.attribute(html, "img", "src")
        Enum.each(img_srcs, fn img_src ->
          state.data_store.put(
            {:via, Registry, {state.scraper_id, :data_store}},
            Scraper.Link.fix(img_src, state.link)
          )
        end)

      {:error, %HTTPoison.Error{reason: reason}} ->
        Logger.error(inspect(reason))
    end

    {:stop, :shutdown, state}
  end
end
