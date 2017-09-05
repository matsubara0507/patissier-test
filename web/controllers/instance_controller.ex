defmodule PastryChefTest.InstanceController do
  require OK
  import SweetXml
  use PastryChefTest.Web, :controller

  def show(conn, %{"id" => id}) do
    result = OK.with do
      response <- fetch_ec2_instances_info(id)
      case parse_instances_info(response) do
        [ ] -> OK.failure "#{id} is not found..."
        [ instance_info | _ ] -> OK.success instance_info
      end
    end
    case result do
      {:ok, term} ->
        render conn, instance: term
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end

  def deploy(conn, params = %{"id" => id}) do
    env = Application.get_env(:pastry_chef_test, PastryChefTest.InstanceController)
    branch1 = params["html-dump1"]
    branch2 = params["html-dump2"]
    result = OK.with do
      _ <- update_ec2_instance_tags(id, [{:html_dump1, branch1}, {:html_dump2, branch2}])
      response <- fetch_ec2_instances_info(id)
      public_ip_address = parse_public_ip_address(response)
      IO.inspect public_ip_address
      conn <- connect_ssh_repeat(public_ip_address, env[:key_path])
      IO.inspect "ssh success!"
      dir = "/home/ec2-user/"
      SSHEx.cmd! conn, "echo '#{branch1} and #{branch2}' > #{dir}/index.html"
      OK.success "run `ssh -i #{env[:key_path]}/id_rsa ec2-user@#{public_ip_address} cat index.html`"
    end
    case result do
      {:ok, term} ->
        render conn, message: "success! branch1: #{branch1}, branch2: #{branch2}\n#{inspect(term)}"
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end

  def create(conn, params) do
    env = Application.get_env(:pastry_chef_test, PastryChefTest.InstanceController)
    branch1 = params["html-dump1"]
    branch2 = params["html-dump2"]
    name = params["name"]
    result = OK.with do
      response1 <- run_ec2_instance(env[:image_id], env[:key_name], name, branch1, branch2)
      instance_id = parse_instance_id(response1)
      IO.inspect instance_id
      _ <- wait_running(instance_id)
      IO.inspect "instance is running!"
      _ <- wait_status_ok(instance_id)
      IO.inspect "instance status is OK!"
      response2 <- fetch_ec2_instances_info(instance_id)
      public_ip_address = parse_public_ip_address(response2)
      IO.inspect public_ip_address
      # IO.inspect System.cmd("ping", ["-c", "1", public_ip_address])
      conn <- connect_ssh_repeat(public_ip_address, env[:key_path])
      IO.inspect "ssh success!"
      dir = "/home/ec2-user/"
      SSHEx.cmd! conn, "echo '#{branch1} and #{branch2}' > #{dir}/index.html"
      OK.success "run `ssh -i #{env[:key_path]}/id_rsa ec2-user@#{public_ip_address} cat index.html`"
    end
    case result do
      {:ok, term} ->
        render conn, message: "success! branch1: #{branch1}, branch2: #{branch2}\n#{inspect(term)}"
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end

  def instances(conn, _param) do
    result = OK.with do
      response <- fetch_ec2_instances_info()
      instances_info = parse_instances_info(response)
      IO.inspect instances_info
      OK.success instances_info
    end
    case result do
      {:ok, term} ->
        render conn, instances: term
      {:error, term} ->
        render conn, message: "error: #{inspect(term)}"
    end
  end

  defp run_ec2_instance(image_id, key_name, name, branch1, branch2) do
    ExAws.EC2.run_instances(image_id, 1, 1,
      [ key_name: key_name,
        instance_type: "t2.micro",
        tag_specifications: [
          { :instance,
            [ {:project, "pastry-chef"},
              {:Name, name},
              {:html_dump1, branch1},
              {:html_dump2, branch2}]
          }]
      ])
    |> ExAws.request
  end

  defp fetch_ec2_instances_info(instance_id) do
    ExAws.EC2.describe_instances([instance_ids: [instance_id]])
    |> ExAws.request
  end

  defp fetch_ec2_instances_info() do
    ExAws.EC2.describe_instances([filters: [{"tag:project", "pastry-chef"}]])
    |> ExAws.request
  end

  defp fetch_ec2_instance_status(instance_id) do
    ExAws.EC2.describe_instance_status([instance_ids: [instance_id]])
    |> ExAws.request
  end

  defp update_ec2_instance_tags(instance_id, tags) do
    ExAws.EC2.create_tags([instance_id], tags)
    |> ExAws.request
  end

  defp parse_instance_id(response) do
    SweetXml.xpath(response[:body], ~x"//instanceId/text()"s)
  end

  defp parse_public_ip_address(response) do
    SweetXml.xpath(response[:body], ~x"//networkInterfaceSet/item/association/publicIp/text()"s)
  end

  defp parse_instance_state_name(response) do
    SweetXml.xpath(response[:body], ~x"//instanceState/name/text()"s)
  end

  defp parse_instance_status(response) do
    SweetXml.xpath(response[:body], ~x"//instanceStatus/status/text()"s)
  end

  defp parse_instances_info(response) do
    SweetXml.xpath(response[:body],
      ~x"//instancesSet/item"l,
      instance_id: ~x"//instanceId/text()"s,
      public_ip: ~x"//networkInterfaceSet/item/association/publicIp/text()"s,
      state: ~x"//instanceState/name/text()"s,
      tags: [
        ~x"//tagSet/item"l,
        key: ~x"//key/text()"s,
        value: ~x"//value/text()"s
      ]
    )
  end

  defp wait_running(instance_id) do
    :timer.sleep(2000)
    IO.inspect "wait..."
    OK.with do
      response <- fetch_ec2_instances_info(instance_id)
      case parse_instance_state_name(response) do
        "running" -> OK.success(nil)
        "terminated" -> OK.failure("terminated...")
        _ -> wait_running(instance_id)
      end
    end
  end

  defp wait_status_ok(instance_id) do
    :timer.sleep(2000)
    IO.inspect "wait..."
    OK.with do
      response <- fetch_ec2_instance_status(instance_id)
      case parse_instance_status(response) do
        "ok" -> OK.success(nil)
        _ -> wait_running(instance_id)
      end
    end
  end

  defp connect_ssh_repeat(public_ip_address, key_path) do
    OK.with do
      IO.inspect "connecting..."
      :timer.sleep(2000)
      SSHEx.connect ip: public_ip_address, user: "ec2-user", user_dir: key_path
    else
      :econnrefused -> connect_ssh_repeat(public_ip_address, key_path)
    end
  end
end
