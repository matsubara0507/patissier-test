defmodule PastryChefTest.EC2 do
  require OK
  import SweetXml

  def run_ec2_instance(image_id, key_name, name, tags) do
    ExAws.EC2.run_instances(image_id, 1, 1,
      [ key_name: key_name,
        instance_type: "t2.micro",
        tag_specifications: [
          { :instance,
            [ {:project, "pastry-chef"},
              {:Name, name} ] ++ tags
          }]
      ])
    |> ExAws.request
  end

  def fetch_ec2_instances_info(instance_id) do
    ExAws.EC2.describe_instances([instance_ids: [instance_id]])
    |> ExAws.request
  end

  def fetch_ec2_instances_info() do
    ExAws.EC2.describe_instances([filters: [{"tag:project", "pastry-chef"}]])
    |> ExAws.request
  end

  def fetch_ec2_instance_status(instance_id) do
    ExAws.EC2.describe_instance_status([instance_ids: [instance_id]])
    |> ExAws.request
  end

  def update_ec2_instance_tags(instance_id, tags) do
    ExAws.EC2.create_tags([instance_id], tags)
    |> ExAws.request
  end

  def deploy_ec2_instance(instance_id, key_path, cmd) do
    OK.with do
      response <- fetch_ec2_instances_info(instance_id)
      public_ip_address = parse_public_ip_address(response)
      IO.inspect public_ip_address
      conn <- connect_ssh_repeat(public_ip_address, key_path)
      IO.inspect "ssh success!"
      SSHEx.cmd! conn, cmd
      OK.success "run: ssh -i #{key_path}/id_rsa ec2-user@#{public_ip_address}"
    end
  end

  def start_ec2_instance(instance_id) do
    ExAws.EC2.start_instances([instance_id])
    |> ExAws.request
  end

  def stop_ec2_instance(instance_id) do
    ExAws.EC2.stop_instances([instance_id])
    |> ExAws.request
  end

  def terminate_ec2_instance(instance_id) do
    ExAws.EC2.terminate_instances([instance_id])
    |> ExAws.request
  end

  def parse_instance_id(response) do
    SweetXml.xpath(response[:body], ~x"//instanceId/text()"s)
  end

  def parse_public_ip_address(response) do
    SweetXml.xpath(response[:body], ~x"//networkInterfaceSet/item/association/publicIp/text()"s)
  end

  def parse_instance_state_name(response) do
    SweetXml.xpath(response[:body], ~x"//instanceState/name/text()"s)
  end

  def parse_instance_status(response) do
    SweetXml.xpath(response[:body], ~x"//instanceStatus/status/text()"s)
  end

  def parse_instances_info(response) do
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

  def wait_running(instance_id) do
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

  def wait_status_ok(instance_id) do
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

  def connect_ssh_repeat(public_ip_address, key_path) do
    OK.with do
      IO.inspect "connecting..."
      :timer.sleep(2000)
      SSHEx.connect ip: public_ip_address, user: "ec2-user", user_dir: key_path
    else
      :econnrefused -> connect_ssh_repeat(public_ip_address, key_path)
    end
  end

end
