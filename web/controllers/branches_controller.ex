defmodule PastryChefTest.BranchesController do
  use PastryChefTest.Web, :controller

  def index(conn, _params) do
    token = Application.get_env(:pastry_chef_test, PastryChefTest.BranchesController)[:github_auth_token]
    client = Tentacat.Client.new(%{access_token: token})

    branches = Tentacat.Repositories.Branches.list "elixir-lang", "elixir", client

    render conn, branches: branches
  end

  def create(conn, params) do
    task_def_name = "abcde"
    cluster = "pastry-chef-test"
    env = Application.get_env(:pastry_chef_test, PastryChefTest.BranchesController)
    client = %AWS.Client {
      access_key_id: env[:aws_access_key],
      secret_access_key: env[:aws_secret_key],
      region: "us-east-1",
    endpoint: "amazonaws.com"
    }
    input = %{
      networkMode: "bridge",
      containerDefinitions: [
        %{
          name: "hello_world",
          image: env["image"],
          portMappings: [ %{ hostPort: 80, containerPort: 4000, protocol: "tcp" } ],
          environment: [
            %{ name: "ELIXIR_BRANCH", value: params["branch"] } ],
          memory: 512
        }],
      family: task_def_name
    }

    case AWS.ECS.register_task_definition client, input do
      {:ok, _body, _response} -> render conn, message: "success! branch: #{params["branch"]}"
        case AWS.ECS.run_task client, %{ cluster: cluster, count: 1, taskDefinition: task_def_name } do
          {:ok, _body, _response} -> render conn, message: "success! branch: #{params["branch"]}"
          {:error, error} -> render conn, message: "#{error}"
        end
      {:error, error} -> render conn, message: "#{error}"
    end
  end

end
