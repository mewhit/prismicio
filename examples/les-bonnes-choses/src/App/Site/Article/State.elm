module App.Site.Article.State exposing (..)

import App.Site.Article.Types exposing (..)
import App.Documents.Decoders as Documents
import App.Types exposing (GlobalMsg(SetPrismic, RenderNotFound))
import Basics.Extra exposing (never)
import Prismic as P exposing (Url(Url))
import Task


init : P.Model -> String -> ( Model, Cmd Msg )
init prismic bookmarkName =
    let
        model =
            { article =
                Ok Nothing
            }
    in
        ( model
        , prismic
            |> P.fetchApi
            |> P.bookmark bookmarkName
            |> P.submit Documents.decodeArticle
            |> Task.toResult
            |> Task.perform never SetArticle
        )


update : Msg -> Model -> ( Model, Cmd Msg, List GlobalMsg )
update msg model =
    case msg of
        SetArticle (Err error) ->
            ( { model
                | article = Err error
              }
            , Cmd.none
            , []
            )

        SetArticle (Ok ( response, prismic )) ->
            ( { model
                | article =
                    response.results
                        |> List.head
                        |> Maybe.map .data
                        |> Ok
              }
            , Cmd.none
            , [ SetPrismic prismic ]
                ++ if List.isEmpty response.results then
                    [ RenderNotFound ]
                   else
                    []
            )
