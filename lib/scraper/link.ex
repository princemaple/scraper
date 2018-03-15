defmodule Scraper.Link do
  defstruct [:url, :depth, :referrer]

  @type t :: %__MODULE__{
          url: String.t(),
          depth: non_neg_integer,
          referrer: String.t()
        }

  @spec new(url :: String.t(), referrer :: t) :: t
  def new(url, referrer) do
    %__MODULE__{
      url: fix(url, referrer),
      depth: referrer.depth + 1,
      referrer: referrer.url
    }
  end

  @spec fix(url :: String.t(), referrer :: t) :: String.t()
  def fix(url, referrer) do
    do_fix(url, URI.parse(referrer.url))
  end

  defp do_fix("http://" <> _rest = url, _uri), do: url
  defp do_fix("https://" <> _rest = url, _uri), do: url
  defp do_fix("//" <> _rest = link, uri), do: uri.scheme <> ":" <> link
  defp do_fix("/" <> _rest = path, uri), do: URI.to_string(%{uri | path: path})
  defp do_fix(link, uri), do: URI.to_string(%{uri | path: Path.join(uri.path, link)})

  @spec select(links :: [String.t()], selectors :: [{module, atom, [any]} | Regex.t() | function]) ::
          [String.t()]
  def select(links, selectors, referrer_link) do
    links
    |> Stream.reject(&match?("#" <> _rest, &1))
    |> Stream.map(&Scraper.Link.new(&1, referrer_link))
    |> Stream.filter(&apply_link_selectors(&1, selectors))
  end

  defp apply_link_selectors(link, selectors) do
    Enum.all?(selectors, &apply_link_selector(link.url, &1))
  end

  defp apply_link_selector(url, {m, f, a}), do: apply(m, f, [url | a])
  defp apply_link_selector(url, %Regex{} = regex), do: url =~ regex
  defp apply_link_selector(url, f) when is_function(f), do: f.(url)
end
