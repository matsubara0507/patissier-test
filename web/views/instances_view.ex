defmodule PastryChefTest.InstancesView do
  use PastryChefTest.Web, :view

  def render("instances.json", %{instances: instances}), do: instances
  def render("instances.json", %{message: message}), do: message

  def render("instance.json", %{instance: instance}), do: instance
  def render("instance.json", %{message: message}), do: message

  def render("create.json", %{message: message}), do: message

  def render("rename.json", %{message: message}), do: message
  def render("deploy.json", %{message: message}), do: message
  
  def render("delete.json", %{message: message}), do: message
end
