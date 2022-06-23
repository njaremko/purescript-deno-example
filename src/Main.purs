module Main where

import Prelude
import Data.Argonaut (encodeJson, fromString, stringify, toObject)
import Data.Map as Map
import Data.Maybe (Maybe(..), fromMaybe)
import Data.String (Pattern(..), Replacement(..), replace)
import Data.Tuple (Tuple(..))
import Deno as Deno
import Deno.Dotenv as Dotenv
import Deno.Http (Response, createResponse, hContentTypeHtml, hContentTypeJson, serveListener)
import Deno.Http.Request (Request)
import Deno.Http.Request as Request
import Effect (Effect)
import Effect.Aff (Aff, launchAff_)
import Effect.Console (log)
import Foreign.Object as Object
import Router (Router, Context, makeRouter)
import Router as Router
import Router.Method (Method)
import Router.Method as Method

type AppRouter
  = Router ()

type AppContext
  = Context ()

requestToContext :: Request -> {}
requestToContext _req = {}

requestToMethod :: Request -> Method
requestToMethod = fromMaybe Method.GET <<< Method.fromString <<< Request.method

main :: Effect Unit
main = do
  log "Let's get cookin 🍝"
  e <-
    Dotenv.configSync $ Just
      $ { export: Just true
        , allowEmptyValues: Nothing
        , defaults: Nothing
        , example: Nothing
        , path: Nothing
        , safe: Nothing
        }
  let
    baseUrl = fromMaybe "http://localhost:3001" $ Map.lookup "APP_URL" $ e

    routes =
      Map.fromFoldable
        [ Tuple
            ( Router.makeRoute
                { path: "/", methods: [ Method.GET ]
                }
            )
            indexRoute
        , Tuple
            ( Router.makeRoute
                { path: "/v1/projects/:project/environments/:environment/flags/:flag"
                , methods: [ Method.POST ]
                }
            )
            jsonEcho
        ]

    router =
      makeRouter
        { routes
        , fallbackResponse: (pure $ createResponse "Not Found" (Just { headers: Just $ Map.fromFoldable [ Tuple "content-type" "text/plain" ], status: Just 404, statusText: Just "Not Found" }))
        , requestToPath: \req -> replace (Pattern baseUrl) (Replacement "") $ Request.url req
        , requestToContext
        , requestToMethod
        }

    handler = Router.route router
  listener <- Deno.listen { port: 3001 }
  launchAff_ $ serveListener listener handler Nothing

indexRoute :: Request → AppContext -> Aff Response
indexRoute _req _ctx =
  let
    payload =
      """
    <html>
      <head></head>
      <body>
        <div>
          Hello World!
        </div>
      </body>
    </html>
    """

    headers = Just $ Map.fromFoldable [ hContentTypeHtml ]

    response_options = Just { headers, status: Nothing, statusText: Nothing }
  in
    pure $ createResponse payload response_options

jsonEcho :: Request → AppContext -> Aff Response
jsonEcho req { params } = do
  payload <- Request.json req
  let
    headers = Just $ Map.fromFoldable [ hContentTypeJson ]

    response_options = Just { headers, status: Nothing, statusText: Nothing }

    paramsAsObject = Object.fromFoldable $ map (\(Tuple k v) -> Tuple k (fromString v)) $ (Map.toUnfoldable params :: Array (Tuple String String))

    payloadAsObject = fromMaybe Object.empty $ toObject payload
  pure $ createResponse (stringify $ encodeJson $ Object.union paramsAsObject payloadAsObject) response_options
