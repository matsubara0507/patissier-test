defmodule PastryChefTest.BranchesController do
  require OK
  import SweetXml
  use PastryChefTest.Web, :controller

  def index(conn, _params) do
    token = Application.get_env(:pastry_chef_test, PastryChefTest.BranchesController)[:github_auth_token]
    client = Tentacat.Client.new(%{access_token: token})

    branches = Tentacat.Repositories.Branches.list "matsubara0507", "html-dump", client

    render conn, branches: branches
  end

  def create(conn, params) do
    env = Application.get_env(:pastry_chef_test, PastryChefTest.BranchesController)
    result = OK.with do
      response <- run_ec2_instance(env[:image_id], env[:key_name])
      private_ip_address = parse_private_ip_address(response)
      IO.inspect private_ip_address
      fetch_public_ip_address(private_ip_address)
    end
    case result do
      {:ok, term} ->
        render conn, message: "success! branch: #{params["branch"]}\n #{inspect(term)}"
      {:error, term} ->
        render conn, message: "#{inspect(term)}"
    end
  end

  defp run_ec2_instance(image_id, key_name) do
    ExAws.EC2.run_instances(image_id, 1, 1, [key_name: key_name, instance_type: "t2.micro"])
    |> ExAws.request
  end

  defp parse_private_ip_address(response) do
    SweetXml.xpath(response[:body], ~x"//privateIpAddress/text()")
    |> to_string
  end

  defp fetch_ec2_instance_info(private_ip_address) do
    ExAws.EC2.describe_instances([filters: ["private-ip-address": [private_ip_address]]])
    |> ExAws.request
  end

  defp parse_public_ip_address(response) do
    SweetXml.xpath(response[:body], ~x"//publicIp/text()")
    |> to_string
  end

  defp fetch_public_ip_address(private_ip_address) do
    OK.with do
      response <- fetch_ec2_instance_info(private_ip_address)
      case parse_public_ip_address(response) do
        "" ->
          :timer.sleep(2000)
          IO.inspect "fetch..."
          fetch_public_ip_address(private_ip_address)
        public_ip_address -> OK.success(public_ip_address)
      end
    end
  end
end
