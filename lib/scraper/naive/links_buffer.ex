defmodule Scraper.Naive.LinksBuffer do
  use Agent

  @behaviour Scraper.LinksBuffer

  def start_link(opts) do
    Agent.start_link(
      fn -> [] end,
      name: Keyword.fetch!(opts, :name)
    )
  end

  def enqueue(server, link) do
    Agent.update(server, fn links -> [link | links] end)
  end

  def dequeue(server) do
    Agent.get_and_update(server, fn
      [link | links] -> {{:ok, link}, links}
      [] -> {{:error, :empty}, []}
    end)
  end
end
