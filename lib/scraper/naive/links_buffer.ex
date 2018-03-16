defmodule Scraper.Naive.LinksBuffer do
  use Scraper.LinksBuffer
  use Agent

  @impl true
  def start_link(opts) do
    Agent.start_link(
      fn -> [] end,
      name: Keyword.fetch!(opts, :name)
    )
  end

  @impl true
  def enqueue(server, link) when is_atom(server), do: enqueue(via(server), link)
  def enqueue(server, link) do
    Agent.update(server, fn links -> [link | links] end)
  end

  @impl true
  def dequeue(server) when is_atom(server), do: dequeue(via(server))
  def dequeue(server) do
    Agent.get_and_update(server, fn
      [link | links] -> {{:ok, link}, links}
      [] -> {{:error, :empty}, []}
    end)
  end
end
