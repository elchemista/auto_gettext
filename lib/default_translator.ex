defmodule AutoGettext.DefaultTranslator do
  @behaviour AutoGettext.Translator

  def batch_translate(msgids, _locale) do
    for msgid <- msgids, do: {msgid, "PLACEHOLDER_#{msgid}"}
  end
end
