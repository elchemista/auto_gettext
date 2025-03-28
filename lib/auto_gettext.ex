defmodule AutoGettext do
  @moduledoc """
  Documentation for `AutoGettext`.

  This module can house shared logic, configuration, or helper functions
  that other modules in your library depend on.
  """
end

defmodule AutoGettext.DefaultTranslator do
  @behaviour AutoGettext.Translator

  def batch_translate(msgids, _locale) do
    for msgid <- msgids, do: {msgid, "PLACEHOLDER_#{msgid}"}
  end
end
