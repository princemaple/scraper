defmodule Scraper.LinksBuffer do
  @callback start_link(opts :: Keyword.t) :: GenServer.on_start

  @callback enqueue(GenServer.server, Link.t) :: :ok
  @callback dequeue(GenServer.server) :: {:ok, Link.t} | {:error, reason :: any}
end
