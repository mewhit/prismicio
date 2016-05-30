module App.Site.Products.Types exposing (..)

import App.Site.Products.Index.Types as Index
import App.Site.Products.Product.Types as Product


type alias Model =
    { page : Page
    , content : Content
    }

type Page
  = IndexP (Maybe String)
  | ProductP String String


type Content
  = NoContent
  | IndexC Index.Model
  | ProductC Product.Model


type Msg
    = IndexMsg Index.Msg
    | ProductMsg Product.Msg
