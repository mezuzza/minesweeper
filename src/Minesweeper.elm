module Minesweeper exposing (..)

import Array exposing (Array)
import Array.Extra as Array
import Browser
import Css
import Html.Styled as Html exposing (Html)
import Html.Styled.Attributes exposing (css)
import Html.Styled.Events as Html
import Json.Decode as Json
import List.Extra as List
import Random
import Set exposing (Set)


type alias Flags =
    { rows : Int
    , columns : Int
    , numBombs : Int
    }


type CellState
    = Unknown
    | Flagged
    | Revealed


type ContainsBomb
    = Bomb
    | NoBomb


type alias CellModel =
    ( CellState, ContainsBomb )


type alias CellStates =
    Array (Array CellModel)


type alias Model =
    { cellStates : CellStates
    , rows : Int
    , columns : Int
    }


type alias BombLocations =
    Set Int


type Msg
    = Initialize BombLocations
    | FlagCell ( Int, Int )
    | RevealCell ( Int, Int )


initialBombLocations : Int -> ( Int, Int ) -> Random.Generator BombLocations
initialBombLocations n ( rows, columns ) =
    let
        generateUniqueIntegers : Set Int -> Random.Generator BombLocations
        generateUniqueIntegers generated =
            if Set.size generated < n then
                Random.int 0 (rows * columns - 1)
                    |> Random.andThen
                        (\x -> generateUniqueIntegers (Set.insert x generated))

            else
                Random.constant generated
    in
    generateUniqueIntegers Set.empty


init : Flags -> ( Model, Cmd Msg )
init { rows, columns, numBombs } =
    ( { rows = rows
      , columns = columns
      , cellStates =
            Array.initialize rows
                (\_ ->
                    Array.initialize columns
                        (\_ ->
                            ( Unknown, NoBomb )
                        )
                )
      }
    , Random.generate Initialize
        (initialBombLocations numBombs
            ( rows, columns )
        )
    )


numberToColor : Int -> Css.Color
numberToColor i =
    case i of
        1 ->
            Css.hex "0000ff"

        2 ->
            Css.hex "008000"

        3 ->
            Css.hex "ff0000"

        4 ->
            Css.hex "00008b"

        5 ->
            Css.hex "8b0000"

        6 ->
            Css.hex "00ffff"

        7 ->
            Css.hex "000000"

        8 ->
            Css.hex "808080"

        _ ->
            Css.hex "FFFFFF"


cellStyling : Int -> CellModel -> List Css.Style
cellStyling adjacentBombs cellState =
    let
        backgroundColor =
            Css.hex "cccccc"

        borderTopLeftColor =
            Css.hex "e6e6e6"

        borderBottomRightColor =
            Css.hex "b3b3b3"
    in
    [ Css.width (Css.px 30)
    , Css.height (Css.px 30)
    , Css.displayFlex
    , Css.alignItems Css.center
    , Css.justifyContent Css.center
    , Css.fontFamily Css.monospace
    , Css.fontSize Css.xxLarge
    , Css.color (numberToColor adjacentBombs)
    , Css.borderStyle Css.solid
    , Css.borderWidth (Css.px 6)
    , Css.backgroundColor backgroundColor
    , Css.backgroundSize Css.contain
    ]
        ++ (case cellState of
                ( Revealed, isBomb ) ->
                    let
                        background =
                            case isBomb of
                                Bomb ->
                                    [ Css.backgroundImage
                                        (Css.url "./dist/bomb.png")
                                    ]

                                NoBomb ->
                                    []
                    in
                    [ Css.borderColor backgroundColor
                    ]
                        ++ background

                ( Flagged, _ ) ->
                    [ Css.backgroundImage (Css.url "./dist/flag.svg")
                    , Css.borderTopColor borderTopLeftColor
                    , Css.borderLeftColor borderTopLeftColor
                    , Css.borderBottomColor borderBottomRightColor
                    , Css.borderRightColor borderBottomRightColor
                    ]

                _ ->
                    [ Css.borderTopColor borderTopLeftColor
                    , Css.borderLeftColor borderTopLeftColor
                    , Css.borderBottomColor borderBottomRightColor
                    , Css.borderRightColor borderBottomRightColor
                    ]
           )


rowStyling : Int -> List Css.Style
rowStyling columns =
    [ Css.property "display" "grid"
    , Css.width Css.auto
    , Css.height Css.auto
    , Css.property "grid-template-columns"
        ("repeat("
            ++ String.fromInt columns
            ++ " , auto)"
        )
    , Css.property "grid-template-rows" "auto"
    ]


gridStyling : Int -> List Css.Style
gridStyling rows =
    [ Css.border (Css.px 10)
    , Css.borderStyle Css.solid
    , Css.borderColor (Css.hex "808080")
    , Css.property "display" "grid"
    , Css.property "width" "fit-content"
    , Css.height Css.auto
    , Css.property "grid-template-columns" "auto"
    , Css.property "grid-template-rows"
        ("repeat(" ++ String.fromInt rows ++ " , auto)")
    ]


makeCell : Int -> Int -> Int -> CellModel -> Html Msg
makeCell adjacentBombs row column cellState =
    Html.div
        [ css (cellStyling adjacentBombs cellState)
        , Html.onClick (RevealCell ( row, column ))
        , Html.preventDefaultOn "contextmenu"
            (Json.succeed ( FlagCell ( row, column ), True ))
        ]
        (case ( cellState, adjacentBombs > 0 ) of
            ( ( Revealed, NoBomb ), True ) ->
                [ Html.text (String.fromInt adjacentBombs) ]

            _ ->
                []
        )


countAdjacentBombs : Int -> Int -> CellStates -> Int
countAdjacentBombs row column bombs =
    [ -1, 0, 1 ]
        |> List.andThen
            (\i -> [ -1, 0, 1 ] |> List.map (Tuple.pair i))
        |> List.foldl
            (\( i, j ) b ->
                if i == 0 && j == 0 then
                    b

                else
                    case
                        bombs
                            |> Array.get (row + i)
                            |> Maybe.andThen (Array.get (column + j))
                    of
                        Just ( _, Bomb ) ->
                            b + 1

                        _ ->
                            b
            )
            0


makeGrid : Model -> Html Msg
makeGrid model =
    model.cellStates
        |> Array.indexedMap
            (\r ->
                Array.indexedMap
                    (\c ->
                        let
                            adjacentBombs =
                                countAdjacentBombs r c model.cellStates
                        in
                        makeCell adjacentBombs r c
                    )
                    >> Array.toList
                    >> Html.div
                        [ css (rowStyling model.columns) ]
            )
        |> Array.toList
        |> Html.div
            [ css (gridStyling model.rows) ]


view : Model -> Browser.Document Msg
view model =
    { title = "Minesweeper Elm"
    , body = [ makeGrid model |> Html.toUnstyled ]
    }


locationToIndex : Int -> ( Int, Int ) -> Int
locationToIndex numColumns ( row, column ) =
    row * numColumns + column


updateCellState ( row, column ) f =
    Array.update row (Array.update column (Tuple.mapFirst f))


revealCell : ( Int, Int ) -> CellStates -> CellStates
revealCell loc =
    updateCellState loc
        (\x ->
            case x of
                Unknown ->
                    Revealed

                _ ->
                    x
        )


revealCells : ( Int, Int ) -> CellStates -> CellStates
revealCells loc state =
    let
        ( row, column ) =
            loc

        state_ =
            revealCell loc state

        adjacentBombs =
            countAdjacentBombs row column state_
    in
    case
        ( state
            |> Array.get row
            |> Maybe.andThen (Array.get column)
        , adjacentBombs
        )
    of
        ( Nothing, _ ) ->
            state_

        ( Just ( Unknown, _ ), 0 ) ->
            [ -1, 0, 1 ]
                |> List.andThen
                    (\i -> [ -1, 0, 1 ] |> List.map (Tuple.pair i))
                |> List.map (Tuple.mapFirst (\x -> x + row))
                |> List.map (Tuple.mapSecond (\x -> x + column))
                |> List.foldl revealCells state_

        _ ->
            state_


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    let
        setBombsInCells bombLocations =
            Array.indexedMap
                (\r ->
                    Array.indexedMap
                        (\c ( x, _ ) ->
                            ( x
                            , if
                                Set.member
                                    (locationToIndex model.columns ( r, c ))
                                    bombLocations
                              then
                                Bomb

                              else
                                NoBomb
                            )
                        )
                )
    in
    case msg of
        Initialize bombLocations ->
            ( { model
                | cellStates =
                    setBombsInCells
                        bombLocations
                        model.cellStates
              }
            , Cmd.none
            )

        RevealCell loc ->
            ( { model
                | cellStates =
                    revealCells loc model.cellStates
              }
            , Cmd.none
            )

        FlagCell loc ->
            ( { model
                | cellStates =
                    updateCellState loc
                        (\x ->
                            case x of
                                Unknown ->
                                    Flagged

                                Flagged ->
                                    Unknown

                                _ ->
                                    x
                        )
                        model.cellStates
              }
            , Cmd.none
            )


main : Program Flags Model Msg
main =
    Browser.document
        { init = init
        , view = view
        , update = update
        , subscriptions = \x -> Sub.none
        }
