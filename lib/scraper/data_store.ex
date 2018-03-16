defmodule Scraper.DataStore do
  defmacro __using__(_) do
    quote do
      @behaviour unquote(__MODULE__)

      def via(scraper_id) do
        {:via, Registry, {scraper_id, :data_store}}
      end
    end
  end

  @callback start_link(opts :: Keyword.t) :: GenServer.on_start

  @callback put(GenServer.server, any) :: :ok
  @callback get_all(GenServer.server) :: any
end
