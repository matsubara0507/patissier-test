module Instance.List exposing (..)

import Instance exposing (..)
import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage)
import Routes exposing (Sitemap(NewR, EditR))

import Html exposing (..)
import Html.Attributes exposing (class, href, list, id, style, value)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (succeed, field, string)
import Json.Decode.Extra exposing ((|:))
import List.Extra as List
import Maybe as Maybe

import Data.Composition exposing (..)

type alias Model =
  { instances : RemoteData String Instances
  }

type Msg
  = FetchInstances (Result Http.Error Instances)

model : Model
model =
  { instances = NotRequested
  }

fetchInstances : Cmd Msg
fetchInstances =
  let
    apiUrl = "/api/instances"
    request = Http.get apiUrl instancesDecoder
  in
    Http.send FetchInstances request

view : Model -> Html msg
view model =
  case model.instances of
    NotRequested -> text ""
    Requesting ->
      warningMessage "" "getting instances" (text "")
    Failure error ->
      warningMessage "" error (text "")
    Success page -> viewInstances page

viewInstances : Instances -> Html msg
viewInstances instances =
  div [ class "container mt-4" ]
      [ div [ class "Subhead" ]
            [ h2 [ class "Subhead-heading"] [ text "Exist Instances" ]
            , a [ class "btn btn-primary ml-3"
                , href $ Routes.toString NewR ]
                [ text "New" ]
            ]
      , div [ ]
            [ ul [ class "existing-instances" ] $ List.map viewInstance instances ]
      ]

viewInstance : Instance -> Html msg
viewInstance instance =
  li
    [ class "col-12 d-block width-full py-4 border-bottom"
    , id instance.id
    ]
    [ div [ class "d-inline-block mb-1" ]
          [ h3 [] [ a [ href $ Routes.toString (EditR instance.id) ]
                      [ text $ getInstanceName instance ]
                  ] ]
    , div [ class "f6 text-gray mt-2" ]
          [ text $ "instance id is " ++ instance.id ]
    , div [ class "f6 text-gray mt-2" ]
          [ text $ "public ip is " ++ instance.publicIp ]
    , div [ class "topics-row-container col-9 d-inline-flex flex-wrap flex-items-center f6 my-1" ]
          $ List.map viewTag instance.tags
    , div [ class "f6 text-gray mt-2"]
          [ span [ class "instance-state-color ml-0"
                 , style [("backgroundColor", stateColor instance.state)]
                 ] []
          , span [ class "ml-1 mr-3" ] [ text instance.state ]
          ]
    ]

viewTag : Tag -> Html msg
viewTag tag =
  a [ class "topic-tag topic-tag-link f6 my-1" ]
    [ text $ tag.key ++ ":" ++ tag.value ]

update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    FetchInstances (Ok response) ->
      ({ model | instances = Success response }, Cmd.none)
    FetchInstances (Err error) ->
      ({ model | instances = Failure $ "Something went wrong....." ++ toString error }, Cmd.none)
