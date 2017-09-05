defmodule PastryChefTest.InstanceView do
  use PastryChefTest.Web, :view

  def render("create.json", %{message: message}), do: message

  def render("deploy.json", %{message: message}), do: message

  def render("show.json", %{instance: instance}), do: instance
  def render("show.json", %{message: message}), do: message

  def render("instances.json", %{instances: instances}), do: instances
  def render("instances.json", %{message: message}), do: message
end
