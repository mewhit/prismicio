module App.Documents.Decoders exposing (..)

import App.Documents.Types exposing (..)
import Json.Decode exposing (..)
import Prismic.Decoders exposing (..)


decodeArticle : Decoder Article
decodeArticle =
    at [ "data", "article" ]
        (succeed Article
            |: at [ "content", "value" ] decodeStructuredText
            |: at [ "image", "value" ] decodeImageField
            |: at [ "short_lede", "value" ] decodeStructuredText
            |: at [ "title", "value" ] decodeStructuredText
        )


decodeJobOffer : Decoder JobOffer
decodeJobOffer =
    at [ "data", "job-offer" ]
        (succeed JobOffer
            |: at [ "name", "value" ] decodeStructuredText
            |: maybe (at [ "contract_type", "value" ] string)
            |: maybe (at [ "service", "value" ] string)
            |: at [ "job_description", "value" ] decodeStructuredText
            |: at [ "profile", "value" ] decodeStructuredText
            |: at [ "location" ] (list decodeLink)
        )


decodeBlogPost : Decoder BlogPost
decodeBlogPost =
    let
        decodeAllowComments str =
            case str of
                "Yes" ->
                    succeed True

                "No" ->
                    succeed False

                _ ->
                    fail ("Unknown allow_comments value: " ++ str)
    in
        at [ "data", "blog-post" ]
            (succeed BlogPost
                |: at [ "body", "value" ] decodeStructuredText
                |: at [ "author", "value" ] string
                |: at [ "category", "value" ] string
                |: at [ "date", "value" ] string
                |: at [ "shortlede", "value" ] decodeStructuredText
                |: at [ "relatedpost" ] (list decodeLink)
                |: at [ "relatedproduct" ] (list decodeLink)
                |: at [ "allow_comments", "value" ] (string `andThen` decodeAllowComments)
            )
