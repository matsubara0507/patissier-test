module Routes exposing (Sitemap(..), parsePath, navigateTo, toString)

import Navigation exposing (Location)
import Route exposing ((:=))

import Data.Composition exposing (..)

type Sitemap
  = HomeR
  | NewR
  | NotFoundR

homeR = HomeR := Route.static ""
newR = NewR := Route.static "new"

sitemap = Route.router [ homeR, newR ]

match : String -> Sitemap
match = Route.match sitemap >> Maybe.withDefault NotFoundR

toString : Sitemap -> String
toString r =
  case r of
    HomeR -> Route.reverse homeR []
    NewR -> Route.reverse newR []
    NotFoundR -> Debug.crash "cannot render NotFound"

parsePath : Location -> Sitemap
parsePath = match . .pathname

navigateTo : Sitemap -> Cmd msg
navigateTo = Navigation.newUrl . toString
