defmodule AutoGettext.Translator do
  @callback batch_translate([String.t()], String.t()) :: [{String.t(), String.t()}]
end
