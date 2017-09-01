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
  end

  # Other scopes may use custom stacks.
  scope "/api", PastryChefTest do
    pipe_through :api

    get "/branches", BranchesController, :index
    post "/branches", BranchesController, :create
    get "/instances", BranchesController, :instances
  end
end
