defmodule AutoGettext.PO.Parser do
  @moduledoc """
  Loose parser: grabs every msgid/msgstr in sequence from the AI response.
  """

  @spec parse(String.t()) :: {:ok, [{String.t(), String.t()}]} | {:error, :no_matches}
  def parse(text) do
    ids =
      Regex.scan(~r/msgid\s+"([^"]*)"/, text, capture: :all_but_first)
      |> List.flatten()

    trs =
      Regex.scan(~r/msgstr\s+"([^"]*)"/, text, capture: :all_but_first)
      |> List.flatten()

    pairs = Enum.zip(ids, trs)

    if pairs == [],
      do: {:error, :no_matches},
      else: {:ok, Enum.map(pairs, fn {id, tr} -> {unescape(id), unescape(tr)} end)}
  end

  defp unescape(str) do
    str
    |> String.replace(~S(\"), ~s(\"))
    |> String.replace(~S(\\n), "\n")
  end
end
