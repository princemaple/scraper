defmodule Scraper.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(opts \\ []) do
    {server_opts, opts} = Keyword.split(opts, [:name])
    DynamicSupervisor.start_link(__MODULE__, opts, server_opts)
  end

  def init(opts) do
    DynamicSupervisor.init([strategy: :one_for_one] ++ opts)
  end
end
