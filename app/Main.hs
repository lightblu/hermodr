{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE ExtendedDefaultRules #-}

module Main where

import Control.Monad.IO.Class (liftIO)

import Data.Monoid        ((<>), mconcat, mempty)
import Data.Bson          (valueAt, (!?), Label, typed, Field(..))
import Data.Text          (Text, replace, unpack)
import Data.Text.Encoding (encodeUtf8, encodeUtf8Builder )


import Database.MongoDB       (Action, Document, Document, Value(..), access,
                              close, connect, delete, exclude, find,
                              host, insertMany, master, project, rest,
                              select, sort, (=:), useDb, runCommand)

import Database.MongoDB.Admin (serverStatus, admin)

import Control.Monad.Trans (MonadIO, liftIO)

import Data.ByteString.Builder (Builder, byteString, char8, intDec, string8,
                                toLazyByteString, stringUtf8, int64Dec,
                                floatDec, int32Dec, doubleDec)


import Network.HTTP.Types (hContentType, methodGet, status200, status404)

import Network.Wai (Application, Request, Response,
                    pathInfo, requestMethod, responseBuilder, responseLBS)

import Network.Wai.Handler.Warp             (Port, run)

------------------------------------------------------------------------------
-- MongoDB does not have this, copycat from DataBase.MongoDB.Admin.serverStatus
------------------------------------------------------------------------------

replSetGetStatus :: (MonadIO m) => Action m Document
replSetGetStatus = useDb admin $ runCommand ["replSetGetStatus" =: (1 :: Int)]


getInteger :: Label -> Document -> Integer
getInteger label = typed . (valueAt label)

getString :: Label -> Document -> String
getString label = typed . (valueAt label)

getDoc :: Label -> Document -> Document
getDoc label = typed . (valueAt label)


------------------------------------------------------------------------------
-- Tmp stuff
------------------------------------------------------------------------------

instance Show Builder where
   show x = "[Builder " ++ show(toLazyByteString x) ++ "]"


test :: Text -> Text
test path
    | path == "hm" = "yo"
    | otherwise = "nop"


text :: Text -> Builder
text = byteString . encodeUtf8

-- see https://github.com/mongodb-haskell/bson/blob/master/Data/Bson.hs
-- https://hackage.haskell.org/package/bytestring-0.10.8.1/docs/Data-ByteString-Builder.html#g:1
--
valToB :: Value -> Builder
valToB v = case v of
            Float x   -> doubleDec x
            String x  -> encodeUtf8Builder x
            Doc x     -> string8 "!doc"
            Array x   -> string8 "!arr"
            Bin x     -> string8 "!bin"
            Fun x     -> string8 "!fun"
            Uuid x    -> string8 "!uuid"
            Md5 x     -> string8 "!md5"
            UserDef x -> string8 "!ud"
            ObjId x   -> string8 "!objid"
            Bool x    -> string8 "!bool"
            UTC x     -> string8 "!UTC"
            Null      -> string8 "NULL"
            RegEx x   -> string8 "!re"
            JavaScr x -> string8 "!js"
            Sym x     -> string8 "!sym"
            Int32 x   -> int32Dec x
            Int64 x   -> int64Dec x
            Stamp x   -> string8 "!stamp"
            MinMax x  -> string8 "!minmax"


promBuilder :: String -> [Label] -> Builder -> [(String, String)] -> Document -> Builder
promBuilder ctype fnames pname labels doc
-- Descend into nested fields, build up pname
  | fn1:fn2:fns <- fnames = promBuilder ctype (fn2:fns) newpname labels (getDoc fn1 doc)
-- Arrived in nested field, now print val of this
  | fn1:[] <- fnames = (string8 "# TYPE ") <> newpname <> string8 " " <> string8 ctype <> string8 "\n" <> promBuilder2 newpname labels (valueAt fn1 doc) <> string8 "\n"
  where
    newpname = (pname <> string8 "_" <> encodeUtf8Builder (head fnames))


promBuilder2 :: Builder -> [(String, String)] -> Value -> Builder
-- In case of empty document we are done for a document
promBuilder2 pname labels (Doc []) = mempty
-- In case field is a document print this keyed and recurse for more fields to come
promBuilder2 pname labels (Doc ((labl := valu):xs)) =
    (pname) <> (labelsToBuilder (("key",unpack labl):labels)) <> string8 " " <>
    valToB (valu) <> (string8 "\n") <> (promBuilder2 pname labels (Doc xs))
-- In case field is just a simple Value
promBuilder2 pname labels v = (pname) <> (labelsToBuilder labels) <> string8 " " <> valToB (v) <> (string8 "\n")


labelsToBuilder :: [(String, String)] -> Builder
labelsToBuilder [] = (string8 "")
labelsToBuilder lables = (string8 "{") <> allLabels <> (string8 "}")
   where
     allLabels = foldr1 combineLabels (map labelToBuilder lables)
     combineLabels l1 l2 = l1 <> (string8 ",") <> l2
     labelToBuilder (lblkey, lblval) = string8 lblkey <> string8 "=\"" <> string8 lblval <> string8 "\""

------------------------------------------------------------------------------
-- Working version - Getting stats from mongo
------------------------------------------------------------------------------

main = do
    liftIO $ putStrLn "Starting..."
    liftIO $ run 8080 app2

app2 :: Application
app2 request respond = do
    putStrLn ("Serving request: " ++ show(request))

    ssDoc <- fetchMongoServerStatus

    let labels = [("host", getString "host" ssDoc)]
    let prom ctype fnames = promBuilder ctype fnames "mongo" labels ssDoc

    let metrics = prom "counter" ["uptimeMillis"] <>
                  prom "counter" ["network"] <>
                  prom "gauge" ["connections", "current"]

    app metrics request respond


app :: Builder -> Application
app x request respond
    | True = respond prometheusResponse
    | otherwise = respond response404
  where
    prometheusResponse = responseBuilder status200 headers x
    headers = [(hContentType, "text/plain; version=0.0.4")]


fetchMongoServerStatus :: IO (Document)
fetchMongoServerStatus = do
    pipe <- connect (host "172.17.0.1")
    e <- access pipe master admin getMongoServerStatus
    close pipe
    -- print e
    return e


getMongoServerStatus :: Action IO (Document)
getMongoServerStatus = do
    stats <- serverStatus
    -- printDocs "serverStatus" [stats]
    return stats


response404 :: Response
response404 = responseLBS status404 header404 body404
  where
    header404 = [(hContentType, "text/plain")]
    body404 = "404"


printDocs :: String -> [Document] -> Action IO ()
printDocs title docs = liftIO $ putStrLn title >> mapM_ (print . exclude ["_id"]) docs


printDoc :: String -> Document -> Action IO ()
printDoc title doc = liftIO $ putStrLn title >> (print . exclude ["_id"]) doc

