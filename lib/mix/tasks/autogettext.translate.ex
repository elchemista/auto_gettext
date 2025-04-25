defmodule Mix.Tasks.AutoGettext.Translate do
  use Mix.Task
  @shortdoc "Auto-translate missing msgstr in .po files."

  @impl true
  def run(args) do
    {:ok, _} = Application.ensure_all_started(:httpoison)
    root = Enum.at(args, 0, "priv/gettext")
    AutoGettext.translate_missing!(root)
  end
end
