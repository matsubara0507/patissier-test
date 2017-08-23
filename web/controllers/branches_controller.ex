defmodule PastryChefTest.BranchesController do
  use PastryChefTest.Web, :controller

  def index(conn, _params) do
    token = Application.get_env(:pastry_chef_test, PastryChefTest.BranchesController)[:github_auth_token]
    IO.puts "token: #{token}"
    client = Tentacat.Client.new(%{access_token: token})

    branches = Tentacat.Repositories.Branches.list "elixir-lang", "elixir", client

    render conn, branches: branches
  end
end
