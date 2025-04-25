defmodule AutoGettext.Translator do
  @moduledoc """
  Behaviour for batch translation engines. Implement `c:batch_translate/2`.
  """

  @typedoc "Pairs of {msgid, translated_msgstr}"
  @type translation_pair :: {String.t(), String.t()}

  @callback batch_translate([String.t()], locale :: String.t()) ::
              [translation_pair] | :no_translations
end
