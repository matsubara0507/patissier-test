module Instance.List exposing (..)

import Types.RemoteData exposing (RemoteData(..))
import Utils exposing (warningMessage)

import Html exposing (..)
import Html.Attributes exposing (class, list, id, value)
import Html.Events exposing (..)
import Http
import Json.Decode as JD exposing (succeed, field, string)
import Json.Decode.Extra exposing ((|:))

import Data.Composition exposing (..)

type alias Instance =
  { id : String
  , publicIp : String
  , tags : List Tag
  }
type alias Instances = List Instance

type alias Tag = { key : String, value : String }

type alias Model =
  { instances : RemoteData String Instances
  }

type Msg
  = FetchInstances (Result Http.Error Instances)

instancesDecorder : JD.Decoder Instances
instancesDecorder = succeed Instance
                 |: (field "instance_id" string)
                 |: (field "public_ip" string)
                 |: (field "tags" (JD.list tagDecorder))
                 |> JD.list

tagDecorder : JD.Decoder Tag
tagDecorder = succeed Tag
           |: (field "key" string)
           |: (field "value" string)

model : Model
model =
  { instances = NotRequested
  }

fetchInstances : Cmd Msg
fetchInstances =
  let
    apiUrl = "/api/instances"
    request = Http.get apiUrl instancesDecorder
  in
    Http.send FetchInstances request

view : Model -> Html msg
view model =
  case model.instances of
    NotRequested -> text ""
    Requesting ->
      warningMessage "fa fa-spin fa-cog fa-2x fa-fw" "getting branches" (text "")
    Failure error ->
      warningMessage "fa fa-meh-o fa-stack-2x" error (text "")
    Success page -> viewInstances page

viewInstances : Instances -> Html msg
viewInstances instances =
  div [ class "container mt-4" ]
      [ div [ class "Subhead" ]
            [ h2 [ class "Subhead-heading"] [ text "Exist Instances" ]
            , p  [ class "Subhead-description"]
                 [ text "" ]
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
          [ h3 [] [ text $ "instance_id: ", text instance.id ] ]
    , div [ class "f6 text-gray mt-2" ]
          [ text $ "public ip is " ++ instance.publicIp ]
    , div [ class "topics-row-container col-9 d-inline-flex flex-wrap flex-items-center f6 my-1" ]
          $ List.map viewTag instance.tags
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
