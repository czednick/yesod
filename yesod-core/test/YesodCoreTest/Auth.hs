{-# LANGUAGE OverloadedStrings, TemplateHaskell, QuasiQuotes, TypeFamilies, MultiParamTypeClasses #-}
module YesodCoreTest.Auth (specs, Widget) where

import Yesod.Core
import Test.Hspec
import Network.Wai.Test
import Network.Wai
import qualified Data.ByteString.Char8 as S8
import qualified Data.Text as T

data App = App

mkYesod "App" [parseRoutes|
/no-auth NoAuthR
/needs-login NeedsLoginR
/read-only ReadOnlyR
/forbidden ForbiddenR
|]

instance Yesod App where
    isAuthorized NoAuthR _ = return Authorized
    isAuthorized NeedsLoginR _ = return AuthenticationRequired
    isAuthorized ReadOnlyR False = return Authorized
    isAuthorized ReadOnlyR True = return $ Unauthorized "Read only"
    isAuthorized ForbiddenR _ = return $ Unauthorized "Forbidden"
    authRoute _ = Just NoAuthR

handleNoAuthR, handleNeedsLoginR, handleReadOnlyR, handleForbiddenR :: Handler ()
handleNoAuthR = return ()
handleNeedsLoginR = return ()
handleReadOnlyR = return ()
handleForbiddenR = return ()

test :: String -- ^ method
     -> String -- ^ path
     -> (SResponse -> Session ())
     -> Spec
test method path f = it (method ++ " " ++ path) $ do
    app <- toWaiApp App
    flip runSession app $ do
        sres <- request defaultRequest
            { requestMethod = S8.pack method
            , pathInfo = [T.pack path]
            }
        f sres

specs :: Spec
specs = describe "Auth" $ do
    test "GET" "no-auth" $ \sres -> assertStatus 200 sres
    test "POST" "no-auth" $ \sres -> assertStatus 200 sres
    test "GET" "needs-login" $ \sres -> assertStatus 303 sres
    test "POST" "needs-login" $ \sres -> assertStatus 303 sres
    test "GET" "read-only" $ \sres -> assertStatus 200 sres
    test "POST" "read-only" $ \sres -> assertStatus 403 sres
    test "GET" "forbidden" $ \sres -> assertStatus 403 sres
    test "POST" "forbidden" $ \sres -> assertStatus 403 sres