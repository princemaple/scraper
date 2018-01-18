defmodule Scraper.Worker do
  use GenServer, restart: :temporary

  require Logger

  def start_link(url, server_otps \\ []) do
    GenServer.start_link(__MODULE__, url, server_otps)
  end

  def init(url) do
    send self(), :start
    {:ok, url}
  end

  def handle_info(:start, url) do
    case HTTPoison.get(url, [], [follow_redirect: true]) do
      {:ok, %{body: body}} ->
        html = Floki.parse(body)
        links = Floki.attribute(html, "a", "href")
        img_srcs = Floki.attribute(html, "img", "src")
        Agent.update(Scraper.LinksBuffer, fn buffer ->
          buffer ++ filter_links(links, url)
        end)
        Agent.update(Scraper.DataStore, fn store ->
          MapSet.union(store, MapSet.new(img_srcs))
        end)
      {:error, reason} ->
        Logger.error(reason)
    end

    {:stop, :shutdown, url}
  end

  defp filter_links(links, url) do
    links
    |> Enum.reject(&match?("#" <> _rest, &1))
    |> Enum.map(&unify(&1, URI.parse(url)))
  end

  defp unify("http://" <> _rest = url, _uri), do: url
  defp unify("https://" <> _rest = url, _uri), do: url
  defp unify("//" <> _rest = link, _uri), do: "https:" <> link
  defp unify("/" <> _rest = path, uri), do: URI.to_string(%{uri | path: path})
  defp unify(link, uri), do: URI.to_string(%{uri | path: Path.join(uri.path, link)})
end
