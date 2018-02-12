defmodule Scraper.Link do
  defstruct [:url, :depth, :referrer]

  @type t :: %__MODULE__{
    url: String.t,
    depth: non_neg_integer,
    referrer: String.t
  }

  @spec new(url :: String.t, referrer :: t) :: t
  def new(url, referrer) do
    %__MODULE__{
      url: fix(url, referrer),
      depth: referrer.depth + 1,
      referrer: referrer.url
    }
  end

  @spec fix(url :: String.t, referrer :: t) :: String.t
  def fix(url, referrer) do
    do_fix(url, URI.parse(referrer.url))
  end

  defp do_fix("http://" <> _rest = url, _uri), do: url
  defp do_fix("https://" <> _rest = url, _uri), do: url
  defp do_fix("//" <> _rest = link, uri), do: uri.scheme <> ":" <> link
  defp do_fix("/" <> _rest = path, uri), do: URI.to_string(%{uri | path: path})
  defp do_fix(link, uri), do: URI.to_string(%{uri | path: Path.join(uri.path, link)})
end
