defmodule PastryChefTest.BranchesController do
  use PastryChefTest.Web, :controller

  def index(conn, _params) do
    token = Application.get_env(:pastry_chef_test, PastryChefTest.BranchesController)[:github_auth_token]
    client = Tentacat.Client.new(%{access_token: token})

    branches = Tentacat.Repositories.Branches.list "matsubara0507", "html-dump", client

    render conn, branches: branches
  end

  def create(conn, params) do
    env = Application.get_env(:pastry_chef_test, PastryChefTest.BranchesController)
    result =
      ExAws.EC2.run_instances(env[:image_id], 1, 1, [key_name: env[:key_name], instance_type: "t2.micro"])
      |> ExAws.request
    case result do
      {:ok, term} ->
        render conn, message: "success! branch: #{params["branch"]}\n #{term[:body]}"
      {:error, term} ->
        render conn, message: "#{term[:body]}"
    end
  end

end
