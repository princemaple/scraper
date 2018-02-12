defmodule Scraper.DataStore do
  @callback start_link(opts :: Keyword.t) :: GenServer.on_start

  @callback put(GenServer.server, any) :: :ok
  @callback get_all(GenServer.server) :: any
end
