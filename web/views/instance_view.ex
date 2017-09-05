defmodule PastryChefTest.InstanceView do
  use PastryChefTest.Web, :view

  def render("create.json", %{message: message}), do: message

  def render("instances.json", %{instances: instances}), do: instances
  def render("instances.json", %{message: message}), do: message
end
