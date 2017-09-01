module Routes exposing (Sitemap(..), parsePath, navigateTo, toString)

import Navigation exposing (Location)
import Route exposing (..)

type Sitemap
  = HomeR
  | NewR
  | NotFoundR

homeR = HomeR := static ""
newR = NewR := static "new"

sitemap = router [ homeR, newR ]

match : String -> Sitemap
match = Route.match sitemap >> Maybe.withDefault NotFoundR

toString : Sitemap -> String
toString r =
  case r of
    HomeR -> reverse homeR []
    NewR -> reverse newR []
    NotFoundR -> Debug.crash "cannot render NotFound"

parsePath : Location -> Sitemap
parsePath = .pathname >> match

navigateTo : Sitemap -> Cmd msg
navigateTo = toString >> Navigation.newUrl
