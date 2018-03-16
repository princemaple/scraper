defmodule Scraper.Naive.DataStore do
  use Scraper.DataStore
  use Agent

  @impl true
  def start_link(opts) do
    Agent.start_link(
      &MapSet.new/0,
      name: Keyword.fetch!(opts, :name)
    )
  end

  @impl true
  def put(server, item) when is_atom(server), do: put(via(server), item)
  def put(server, item) do
    Agent.update(server, &MapSet.put(&1, item))
  end

  @impl true
  def get_all(server) when is_atom(server), do: get_all(via(server))
  def get_all(server) do
    Agent.get(server, &MapSet.to_list/1)
  end
end
