defmodule Scraper do
  def queue(url) do
    Agent.update(Scraper.LinksBuffer, fn links -> links ++ [url] end)
  end
end
