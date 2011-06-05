{-# LANGUAGE OverloadedStrings #-}
module Text.Digestive.Heist
    ( input
    {-, inputRead
    , inputCheckBox-}
    {-, inputRadio
    , inputFile-}
    , errors
    , childErrors
    {-, inputList-}
    {-, module Text.Digestive.Forms.Html-}
    ) where

import Control.Monad (forM_, unless, when, join, mplus)
import Control.Monad.Reader (ask)
import Control.Monad.Trans (lift)
import Data.Maybe (fromMaybe)
import Data.Monoid (mempty)
import qualified Data.Map as M

import qualified Text.XmlHtml as X
import Text.Templating.Heist
import Data.Text (Text)
import qualified Data.Text.Encoding as TE
import qualified Data.Text as T
import qualified Data.ByteString as BS
import qualified Data.ByteString.Char8 as B8

import Text.Digestive.Types
import Text.Digestive.Result
import Text.Digestive.Forms (FormInput (..))
import qualified Text.Digestive.Forms as Forms
import qualified Text.Digestive.Common as Common
import Text.Digestive.Forms.Html
import Text.Digestive.Backend.Snap.Heist

input :: (Monad m, Functor m)
         => Text -> Formlet m SnapEnv e [(Text, Splice m)] String
input name def = Form $ do
    allinp <- do env <- ask
                 case env of Environment f -> lift $ lift $ f $ zeroId "" -- since the snap-heist backend gives all regardless, any id
                             NoEnvironment -> return Nothing
    let val = fmap (B8.unpack . BS.concat) $  join $ fmap (M.lookup (TE.encodeUtf8 name) . unSnapEnv) allinp
    let view' = [(T.concat [name, "-", "value"], return [X.TextNode (T.pack $ fromMaybe "" (val `mplus` def))])]
        result' = Ok $ fromMaybe "" $  val
    return (View (const $ view'), result')


{-inputRead :: (Monad m, Functor m, FormInput i f, Show a, Read a)
          => Text
          -> e
          -> Maybe a
          -> Form m i e [(Text, Splice m)] a
inputRead name error' = flip Forms.inputRead error' $ \id' inp ->
  [(T.concat [name, "-", "value"], return [X.TextNode (T.pack $ fromMaybe "" inp)])] 
  
inputCheckBox :: (Monad m, Functor m, FormInput i f)
              => Text
              -> Bool
              -> Form m i e [(Text, Splice m)] Bool
inputCheckBox name inp = flip Forms.inputBool inp $ \id' inp' ->
  [(T.concat [name, "-", "value"], return [X.TextNode "checked"])]
-}

errorSplice :: Monad m => Text -> Splice m
errorSplice error = runChildrenWithText [("error", error)]

errorList :: Monad m => Text -> [Text] -> [(Text, Splice m)]
errorList name errors' = [(T.concat [name, "-", "error"], mapSplices errorSplice errors')]

errors :: Monad m
       => Text
       -> Form m i Text [(Text, Splice m)] ()
errors name = Common.errors $ errorList name

childErrors :: Monad m
            => Text
            -> Form m i Text [(Text, Splice m)] ()
childErrors name = Common.childErrors $ errorList name
