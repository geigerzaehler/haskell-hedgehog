{-# OPTIONS_HADDOCK not-home #-}
module Hedgehog.Internal.Tripping (
    tripping
  ) where

import           Hedgehog.Internal.Property
import           Hedgehog.Internal.Show
import           Hedgehog.Internal.Source


-- | Test that a pair of encode / decode functions are compatible.
--
-- Given a printer from some type 'a -> b', and a parser with a
-- potential failure case 'b -> f a'. Ensure that a valid 'a' round
-- trips through the "print" and "parse" to yield the same 'a'.
--
-- For example, types __should__ have tripping 'Read' and 'Show'
-- instances.
--
-- @
-- trippingShowRead :: (Show a, Read a, Eq a, MonadTest m) => a -> m ()
-- trippingShowRead a = tripping a show readEither
-- @
tripping ::
     (MonadTest m, Applicative f, Show b, Show (f a), Eq (f a), HasCallStack)
  => a
  -> (a -> b)
  -> (b -> f a)
  -> m ()
tripping x encode decode =
  let
    mx =
      pure x

    i =
      encode x

    my =
      decode i
  in
    if mx == my then
      success
    else
      case valueDiff <$> mkValue mx <*> mkValue my of
        Nothing ->
          withFrozenCallStack $
            failWith Nothing $ unlines [
                "━━━ Original ━━━"
              , showPretty mx
              , "━━━ Intermediate ━━━"
              , showPretty i
              , "━━━ Roundtrip ━━━"
              , showPretty my
              ]

        Just diff ->
          withFrozenCallStack $
            failWith
              (Just $ Diff "━━━ " "- Original" "/" "+ Roundtrip" " ━━━" diff) $
              unlines [
                  "━━━ Intermediate ━━━"
                , showPretty i
                ]
