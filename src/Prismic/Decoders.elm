module Prismic.Decoders exposing (..)

import Json.Decode exposing (..)
import List
import Prismic.Types exposing (..)


(|:) : Decoder (a -> b) -> Decoder a -> Decoder b
(|:) =
    object2 (<|)


decodeApi : Decoder Api
decodeApi =
    succeed Api
        |: ("refs" := list decodeRef)
        |: ("bookmarks" := dict string)
        |: ("types" := dict string)
        |: ("tags" := list string)
        |: ("version" := string)
        |: ("forms" := dict decodeForm)
        |: ("oauth_initiate" := string)
        |: ("oauth_token" := string)
        |: ("license" := string)
        |: ("experiments" := decodeExperiments)


decodeRef : Decoder Ref
decodeRef =
    object4 Ref
        ("id" := string)
        ("ref" := string)
        ("label" := string)
        (maybe ("isMasterRef" := bool)
            `andThen` (\val ->
                        case val of
                            Nothing ->
                                succeed False

                            Just x ->
                                succeed x
                      )
        )


decodeUrl : Decoder Url
decodeUrl =
    object1 Url string


decodeForm : Decoder Form
decodeForm =
    object6 Form
        ("method" := string)
        ("enctype" := string)
        ("action" := decodeUrl)
        ("fields" := dict decodeField)
        (maybe ("rel" := string))
        (maybe ("name" := string))


decodeField : Decoder Field
decodeField =
    object3 Field
        ("type" := decodeFieldType)
        ("multiple" := bool)
        (maybe ("default" := string))


decodeFieldType : Decoder FieldType
decodeFieldType =
    customDecoder string
        (\str ->
            case str of
                "String" ->
                    Ok String

                "Integer" ->
                    Ok Integer

                _ ->
                    Err ("Unknown field type: " ++ str)
        )


decodeExperiments : Decoder Experiments
decodeExperiments =
    succeed Experiments
        |: ("draft" := list string)
        |: ("running" := list string)


nullOr : Decoder a -> Decoder (Maybe a)
nullOr decoder =
    oneOf
        [ null Nothing
        , map Just decoder
        ]


decodeResponse : Decoder Response
decodeResponse =
    succeed Response
        |: ("license" := string)
        |: ("next_page" := nullOr decodeUrl)
        |: ("page" := int)
        |: ("prev_page" := nullOr decodeUrl)
        |: ("results" := list decodeSearchResult)
        |: ("results_per_page" := int)
        |: ("results_size" := int)
        |: ("total_pages" := int)
        |: ("total_results_size" := int)
        |: ("version" := string)


decodeSearchResult : Decoder SearchResult
decodeSearchResult =
    succeed SearchResult
        |: ("data"
                := dict
                    (dict
                        (oneOf
                            [ object1 (\x -> [ x ]) decodeDocumentField
                            , list decodeDocumentField
                            ]
                        )
                    )
           )
        |: ("href" := decodeUrl)
        |: ("id" := string)
        |: ("linked_documents" := list decodeLinkedDocument)
        |: ("slugs" := list string)
        |: ("tags" := list string)
        |: ("type" := string)
        |: ("uid" := nullOr string)


decodeLinkedDocument : Decoder LinkedDocument
decodeLinkedDocument =
    succeed LinkedDocument
        |: ("id" := string)
        |: ("slug" := string)
        |: ("tags" := list string)
        |: ("type" := string)


decodeDocumentField : Decoder DocumentField
decodeDocumentField =
    ("type" := string)
        `andThen` (\typeStr ->
                    case typeStr of
                        "Text" ->
                            object1 Text ("value" := string)

                        "Select" ->
                            object1 Select ("value" := string)

                        "Color" ->
                            object1 Color ("value" := string)

                        "Number" ->
                            object1 Number ("value" := float)

                        "Date" ->
                            object1 Date ("value" := string)

                        "Image" ->
                            object1 Image ("value" := decodeImageValue)

                        "StructuredText" ->
                            object1 StructuredText ("value" := list decodeStructuredTextField)

                        "Link.document" ->
                            object1 Link decodeLinkField

                        "Link.web" ->
                            object1 Link decodeLinkField

                        _ ->
                            fail ("Unknown document field type: " ++ typeStr)
                  )


decodeImageValue : Decoder ImageValue
decodeImageValue =
    succeed ImageValue
        |: ("main" := decodeImageProperties)
        |: ("views" := (dict decodeImageProperties))


decodeImageProperties : Decoder ImageProperties
decodeImageProperties =
    succeed ImageProperties
        |: ("alt" := nullOr string)
        |: ("copyright" := nullOr string)
        |: ("url" := decodeUrl)
        |: ("dimensions" := decodeImageDimensions)


decodeImageDimensions : Decoder ImageDimensions
decodeImageDimensions =
    succeed ImageDimensions
        |: ("width" := int)
        |: ("height" := int)


decodeStructuredTextField : Decoder StructuredTextField
decodeStructuredTextField =
    ("type" := string)
        `andThen` (\typeStr ->
                    case typeStr of
                        "heading1" ->
                            object1 SSimple (decodeSimpleStructuredTextField Heading1)

                        "heading2" ->
                            object1 SSimple (decodeSimpleStructuredTextField Heading2)

                        "heading3" ->
                            object1 SSimple (decodeSimpleStructuredTextField Heading3)

                        "paragraph" ->
                            object1 SSimple (decodeSimpleStructuredTextField Paragraph)

                        "list-item" ->
                            object1 SSimple (decodeSimpleStructuredTextField ListItem)

                        "image" ->
                            object1 SImage (decodeImageProperties)

                        "embed" ->
                            object1 SEmbed ("oembed" := decodeEmbedProperties)

                        _ ->
                            fail ("Unknown structured field type: " ++ toString typeStr)
                  )


decodeSimpleStructuredTextField : SimpleStructuredTextType -> Decoder SimpleStructuredTextField
decodeSimpleStructuredTextField tag =
    succeed (SimpleStructuredTextField tag)
        |: ("text" := string)
        |: ("spans" := list decodeSpan)


decodeSpan : Decoder Span
decodeSpan =
    succeed Span
        |: ("start" := int)
        |: ("end" := int)
        |: decodeSpanType


decodeSpanType : Decoder SpanType
decodeSpanType =
    ("type" := string)
        `andThen` (\typeStr ->
                    case typeStr of
                        "em" ->
                            succeed Em

                        "strong" ->
                            succeed Strong

                        "hyperlink" ->
                            object1 Hyperlink ("data" := decodeLinkField)

                        _ ->
                            fail ("Unkown span type: " ++ typeStr)
                  )


decodeEmbedProperties : Decoder EmbedProperties
decodeEmbedProperties =
    succeed EmbedProperties
        |: ("author_name" := string)
        |: ("author_url" := decodeUrl)
        |: ("embed_url" := decodeUrl)
        |: ("height" := int)
        |: ("html" := string)
        |: ("provider_name" := string)
        |: ("provider_url" := decodeUrl)
        |: ("thumbnail_height" := int)
        |: ("thumbnail_url" := decodeUrl)
        |: ("thumbnail_width" := int)
        |: ("title" := string)
        |: ("type" := string)
        |: ("version" := string)
        |: ("width" := int)


decodeLinkField : Decoder LinkField
decodeLinkField =
    ("type" := string)
        `andThen` (\typeStr ->
                    case typeStr of
                        "Link.document" ->
                            succeed DocumentLink
                                |: (at [ "value", "document" ] decodeLinkedDocument)
                                |: (at [ "value", "isBroken" ] bool)

                        "Link.web" ->
                            succeed WebLink
                                |: (at [ "value", "url" ] decodeUrl)

                        _ ->
                            fail ("Unknown link type: " ++ typeStr)
                  )
