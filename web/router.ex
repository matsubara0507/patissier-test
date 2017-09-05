defmodule PastryChefTest.Router do
  use PastryChefTest.Web, :router

  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_flash
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", PastryChefTest do
    pipe_through :browser # Use the default browser stack

    get "/", PageController, :index
    get "/new", PageController, :index
    get "/edit/:id", PageController, :index
  end

  # Other scopes may use custom stacks.
  scope "/api", PastryChefTest do
    pipe_through :api

    get "/branches", BranchesController, :branches

    get "/instance/:id", InstanceController, :show
    post "/instance", InstanceController, :create
    put "/instance/:id", InstanceController, :deploy
    get "/instances", InstanceController, :instances
  end
end
