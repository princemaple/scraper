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
        %{link_selectors: link_selectors, data_selectors: _data_selectors} = state
      ) do
    case HTTPoison.get(state.link.url, [], follow_redirect: true) do
      {:ok, %{body: body}} ->
        html = Floki.parse(body)

        if state.link.depth < state.max_depth do
          links = Floki.attribute(html, "a", "href")

          Enum.each(
            select_links(links, link_selectors, state),
            &Scraper.Scheduler.schedule(state.scraper_id, &1)
          )
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

  defp select_links(links, link_selectors, state) do
    links
    |> Stream.reject(&match?("#" <> _rest, &1))
    |> Stream.map(&Scraper.Link.new(&1, state.link))
    |> Stream.filter(&apply_link_selectors(&1, link_selectors))
  end

  defp apply_link_selectors(link, link_selectors) do
    Enum.all?(link_selectors, &apply_link_selector(link.url, &1))
  end

  defp apply_link_selector(url, {m, f, a}), do: apply(m, f, [url | a])
  defp apply_link_selector(url, %Regex{} = regex), do: url =~ regex
  defp apply_link_selector(url, f) when is_function(f), do: f.(url)
end
