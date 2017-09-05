defmodule PastryChefTest.BranchesView do
  use PastryChefTest.Web, :view

  def render("branches.json", %{branches: branches}), do: branches
end
