defmodule PastryChefTest.BranchesView do
  use PastryChefTest.Web, :view

  def render("index.json", %{branches: branches}), do: branches
end
