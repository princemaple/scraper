defmodule Scraper.WorkerSupervisor do
  use DynamicSupervisor

  def start_link(opts \\ []) do
    {name, opts} = Keyword.pop(opts, :name)
    DynamicSupervisor.start_link(__MODULE__, opts, name: name || __MODULE__)
  end

  def init(opts) do
    DynamicSupervisor.init([strategy: :one_for_one] ++ opts)
  end
end
