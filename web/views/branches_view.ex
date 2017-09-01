defmodule PastryChefTest.BranchesView do
  use PastryChefTest.Web, :view

  def render("index.json", %{branches: branches}), do: branches

  def render("create.json", %{message: message}), do: message

  def render("instances.json", %{message: message}), do: message
end
