module Main exposing (..)

import Instance.List as Instances
import Instance.New as New
import Instance.Edit as Edit
import Routes as Routes exposing (Sitemap(..))
import Types.RemoteData exposing (RemoteData(..))

import Html exposing (..)
import Html.Attributes exposing (class, href)
import Html.Events exposing (..)
import List.Extra as List
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
  , editInstance : Edit.Model
  }

type Msg
    = RouteChanged Sitemap
    | RouteTo Sitemap
    | GetInstances Instances.Msg
    | NewInstance New.Msg
    | EditInstance Edit.Msg

init : Location -> (Model, Cmd Msg)
init location =
  let
    route = Routes.parsePath location
  in
    handleRoute route
      { sitemap = route
      , instances = Instances.model
      , newInstance = New.model
      , editInstance = Edit.model
      }

parseRoute : Location -> Msg
parseRoute = RouteChanged . Routes.parsePath

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    RouteChanged route -> handleRoute route model
    RouteTo route -> (model, Routes.navigateTo route)
    GetInstances instancesMsg ->
      (\m -> { model | instances = m}) *** Cmd.map GetInstances
      $ Instances.update instancesMsg model.instances
    NewInstance newInstanceMsg ->
      (\m -> { model | newInstance = m}) *** Cmd.map NewInstance
      $ New.update newInstanceMsg model.newInstance
    EditInstance editInstanceMsg ->
      (\m -> { model | editInstance = m }) *** Cmd.map EditInstance
      $ Edit.update editInstanceMsg model.editInstance

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
      EditR instanceId ->
        (\m -> { model | editInstance = m }) *** Cmd.map EditInstance
        $ Edit.initModel instanceId model.editInstance        
      _ -> (model, Cmd.none)

subscriptions : Model -> Sub msg
subscriptions model = Sub.none


view : Model -> Html Msg
view model =
  div [] [ viewHeader,
    case model.sitemap of
      HomeR -> Html.map GetInstances $ Instances.view model.instances
      NewR -> Html.map NewInstance $ New.view model.newInstance
      EditR instanceId ->
        Html.map EditInstance $ Edit.view instanceId model.editInstance
      NotFoundR -> notFound
  ]

viewHeader : Html Msg
viewHeader =
  header [ class "masthead" ]
         [ div [ class "container" ]
               [ a [ class "masthead-logo"
                   , href $ Routes.toString HomeR
                   , onClick $ RouteTo HomeR ]
                   [ span [ class "mega-octicon octicon-package" ] []
                   , h1 [] [ text "Patissier" ]
                   ]
               ]
         ]

notFound : Html msg
notFound =
    h1 [] [ text "Page not found" ]
