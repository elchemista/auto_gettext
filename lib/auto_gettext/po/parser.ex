defmodule AutoGettext.PO.Parser do
  @moduledoc """
  Minimal PO-snippet parser used to extract `msgid`⇢`msgstr` pairs from the
  AI response.
  """

  @pair ~r/msgid\s+"(?<id>(?:\\.|[^"])*)"\s*msgstr\s+"(?<tr>(?:\\.|[^"])*)"/

  @spec parse(String.t()) :: {:ok, [{String.t(), String.t()}]} | {:error, :no_matches}
  def parse(text) do
    captures =
      Regex.scan(@pair, text, capture: :all_but_first, trim: true)
      |> Enum.map(fn [id, tr] -> {unescape(id), unescape(tr)} end)

    if captures == [], do: {:error, :no_matches}, else: {:ok, captures}
  end

  defp unescape(str) do
    str
    |> String.replace(~S(\"), ~s("))
    |> String.replace(~S(\\n), "\n")
  end
end
