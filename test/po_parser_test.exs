defmodule AutoGettext.PO.ParserTest do
  @moduledoc false
  use ExUnit.Case, async: true
  alias AutoGettext.PO.Parser

  @snippet ~S"""
  msgid "Hello"
  msgstr "Hola"

  msgid "Bye"
  msgstr "Adiós"
  """

  test "parses pairs" do
    assert {:ok, [{"Hello", "Hola"}, {"Bye", "Adiós"}]} = Parser.parse(@snippet)
  end

  test "returns :no_matches on empty" do
    assert {:error, :no_matches} = Parser.parse("")
  end
end
