defmodule Scraper.LinksBuffer do
  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      def via(scraper_id) do
        {:via, Registry, {scraper_id, :links_buffer}}
      end
    end
  end

  @callback start_link(opts :: Keyword.t) :: GenServer.on_start

  @callback enqueue(GenServer.server, Link.t) :: :ok
  @callback dequeue(GenServer.server) :: {:ok, Link.t} | {:error, reason :: any}
end
