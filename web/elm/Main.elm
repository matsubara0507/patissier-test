module Main exposing (..)

import Instance.List as Instances
import Instance.New as New
import Routes as Routes exposing (Sitemap(..))

import Html exposing (..)
import Navigation exposing (Location)

import Data.Composition exposing (..)

main : Program Never Model Msg
main =
  Navigation.program parseRoute
    { init = init
    , update = update
    , view = view
    , subscriptions = subscriptions
    }

type alias Model =
  { sitemap : Sitemap
  , instances : Instances.Model
  , newInstance : New.Model
  }

type Msg
    = RouteChanged Sitemap
    | GetInstances Instances.Msg
    | NewInstance New.Msg

init : Location -> (Model, Cmd Msg)
init location =
  let
    route = Routes.parsePath location
  in
    handleRoute route
      { sitemap = route
      , instances = Instances.model
      , newInstance = New.model
      }

parseRoute : Location -> Msg
parseRoute =
    Routes.parsePath >> RouteChanged

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    RouteChanged route -> handleRoute route model
    GetInstances instancesMsg ->
      (\m -> { model | instances = m}) *** Cmd.map GetInstances
      $ Instances.update instancesMsg model.instances
    NewInstance newInstanceMsg ->
      (\m -> { model | newInstance = m}) *** Cmd.map NewInstance
      $ New.update newInstanceMsg model.newInstance

handleRoute : Sitemap -> Model -> (Model, Cmd Msg)
handleRoute route m =
  let
    model = { m | sitemap = route }
  in
    case route of
      HomeR -> (model, Cmd.map GetInstances Instances.fetchInstances)
      NewR ->
        (\m -> { model | newInstance = m }) *** Cmd.map NewInstance
        $ New.initModel model.newInstance
      _ -> (model, Cmd.none)

subscriptions : Model -> Sub msg
subscriptions model = Sub.none


view : Model -> Html Msg
view model =
  case model.sitemap of
    HomeR -> Html.map GetInstances $ Instances.view model.instances
    NewR -> Html.map NewInstance $ New.view model.newInstance
    NotFoundR -> notFound

notFound : Html msg
notFound =
    h1 [] [ text "Page not found" ]
