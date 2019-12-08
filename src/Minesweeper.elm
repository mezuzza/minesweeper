module Minesweeper exposing (..)

import Browser
import Html exposing (Html)


type alias Model =
    ()


type Msg
    = Msg


init : () -> ( Model, Cmd Msg )
init () =
    ( (), Cmd.none )


view : Model -> Browser.Document Msg
view () =
    { title = "Minesweeper Elm"
    , body = [ Html.div [] [ Html.text "hello world" ] ]
    }


update : Msg -> Model -> ( Model, Cmd Msg )
update Msg () =
    ( (), Cmd.none )


subscriptions : Model -> Sub Msg
subscriptions () =
    Sub.none


main : Program () Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = subscriptions
        }
