module Util.HttpUtil exposing (..)

import Http exposing (..)
import Json.Decode exposing (Decoder)
import Json.Encode as E
import Native.HttpUtil
import Task exposing (..)
import Util.File as File exposing (File(File))


encodeHeaders : List ( String, String ) -> E.Value
encodeHeaders headers =
    E.list (List.map (\( k, v ) -> E.list [ E.string k, E.string v ]) headers)


sendFile : String -> String -> List ( String, String ) -> File.File -> Task a ()
sendFile method url headers (File file) =
    Native.HttpUtil.sendFile method url (encodeHeaders headers) file


makeUrl : String -> List ( String, String ) -> String
makeUrl baseUrl args =
    case args of
        [] ->
            baseUrl

        _ ->
            baseUrl ++ "?" ++ String.join "&" (List.map queryPair args)


queryPair : ( String, String ) -> String
queryPair ( key, value ) =
    Http.encodeUri key ++ "=" ++ Http.encodeUri value


authorization : String -> Header
authorization s =
    Http.header "Authorization" s


authorizationTuple : String -> ( String, String )
authorizationTuple s =
    ( "Authorization", s )


sendJson : String -> Decoder value -> String -> List Header -> Http.Body -> Task Http.Error value
sendJson method decoder url headers body =
    { method = method
    , headers = headers
    , url = url
    , body = body
    , expect = Http.expectJson decoder
    , timeout = Nothing
    , withCredentials = False
    }
        |> Http.request
        |> Http.toTask


sendJsonNoResponse : String -> String -> List Header -> Http.Body -> Task Http.Error ()
sendJsonNoResponse method url headers body =
    { method = method
    , headers = headers
    , url = url
    , body = body
    , expect = Http.expectStringResponse (\_ -> Ok ())
    , timeout = Nothing
    , withCredentials = False
    }
        |> Http.request
        |> Http.toTask


get : Decoder value -> String -> List Header -> Task Http.Error value
get decoder url headers =
    { method = "GET"
    , headers = headers
    , url = url
    , body = Http.emptyBody
    , expect = Http.expectJson decoder
    , timeout = Nothing
    , withCredentials = False
    }
        |> Http.request
        |> Http.toTask


getWithoutCache : Decoder value -> String -> List Header -> Task Http.Error value
getWithoutCache =
    wrapGet
        [ Http.header "Pragma" "no-cache"
        , Http.header "Cache-Control" "no-cache"
        , Http.header "If-Modified-Since" "Thu, 01 Jun 1970 00:00:00 GMT"
        ]


getWithIfModifiedSince : String -> Decoder value -> String -> List Header -> Task Http.Error value
getWithIfModifiedSince ifModifiedSince =
    wrapGet [ Http.header "If-Modified-Since" ifModifiedSince ]


wrapGet : List Header -> Decoder value -> String -> List Header -> Task Http.Error value
wrapGet additionalHeader decoder url headers =
    get decoder url (additionalHeader ++ headers)


postJson : Decoder value -> String -> List Header -> Http.Body -> Task Http.Error value
postJson =
    sendJson "POST"


postJsonNoResponse : String -> List Header -> Http.Body -> Task Http.Error ()
postJsonNoResponse =
    sendJsonNoResponse "POST"


putJson : Decoder value -> String -> List Header -> Http.Body -> Task Http.Error value
putJson =
    sendJson "PUT"


putJsonNoResponse : String -> List Header -> Http.Body -> Task Http.Error ()
putJsonNoResponse =
    sendJsonNoResponse "PUT"


patchJson : Decoder value -> String -> List Header -> Http.Body -> Task Http.Error value
patchJson =
    sendJson "PATCH"


patchJsonNoResponse : String -> List Header -> Http.Body -> Task Http.Error ()
patchJsonNoResponse =
    sendJsonNoResponse "PATCH"


deleteJson : Decoder value -> String -> List Header -> Http.Body -> Task Http.Error value
deleteJson =
    sendJson "DELETE"


deleteJsonNoResponse : String -> List Header -> Http.Body -> Task Http.Error ()
deleteJsonNoResponse =
    sendJsonNoResponse "DELETE"


recover404 : Task Http.Error a -> Task Http.Error (Maybe a)
recover404 task =
    task
        |> Task.map Just
        |> Task.onError
            (\e ->
                case e of
                    Http.BadStatus res ->
                        if res.status.code == 404 then
                            Task.succeed Nothing
                        else
                            Task.fail e

                    e ->
                        Task.fail e
            )
