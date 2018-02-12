defmodule Scraper.Naive.DataStore do
  use Agent

  @behaviour Scraper.DataStore

  def start_link(opts) do
    Agent.start_link(
      &MapSet.new/0,
      name: Keyword.fetch!(opts, :name)
    )
  end

  def put(server, item) do
    Agent.update(server, &MapSet.put(&1, item))
  end

  def get_all(server) do
    Agent.get(server, &MapSet.to_list/1)
  end
end
