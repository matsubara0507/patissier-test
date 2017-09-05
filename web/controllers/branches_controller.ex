defmodule PastryChefTest.BranchesController do
  use PastryChefTest.Web, :controller

  def branches(conn, _params) do
    token = Application.get_env(:pastry_chef_test, PastryChefTest.BranchesController)[:github_auth_token]
    client = Tentacat.Client.new(%{access_token: token})

    branches = Tentacat.Repositories.Branches.list "matsubara0507", "html-dump", client

    render conn, branches: branches
  end
end
