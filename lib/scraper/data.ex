defmodule Scraper.Data do
  @type selector ::
          {:find, String.t()}
          | {:map, [{term, [selector]}]}
          | {:text, Keyword.t()}
          | {:attr, String.t()}
          | {:attr, String.t(), String.t()}

  @spec select(parsed_html :: Floki.html_tree(), [selector()]) :: [map | String.t()]
  def select(parsed_html, [{:find, selector} | rest]) do
    parsed_html |> Floki.find(selector) |> select(rest)
  end

  def select(elems, [{:map, key_commands}]) do
    Enum.map(elems, fn elem ->
      for {k, commands} <- key_commands, into: %{} do
        {k, select([elem], commands)}
      end
    end)
  end

  def select(elems, [{:text, opts}]) do
    Floki.text(elems, opts)
  end

  def select(elems, [{:attr, selector, attr}]) do
    Floki.attribute(elems, selector, attr)
  end

  def select(elems, [{:attr, attr}]) do
    Floki.attribute(elems, attr)
  end
end
