defmodule AutoGettext.Translator do
  @moduledoc """
  Behaviour implemented by modules that AutoGettext can delegate translations to.

  A translator receives a list of PO-formatted snippets (each containing a
  `msgid`/`msgstr` pair) alongside the locale that is being processed. Returned
  values are used to patch the original `.po` files.

  You can provide your own translator by setting the `:translator_module`
  configuration key under the `:auto_gettext` application environment.
  """

  @typedoc "Pairs of {msgid, translated_msgstr}"
  @type translation_pair :: {String.t(), String.t()}

  @callback batch_translate([String.t()], locale :: String.t()) ::
              [translation_pair] | :no_translations
end
