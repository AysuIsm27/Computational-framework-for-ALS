{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies #-}
module Assess where

-- | -----------------------------------------------------------------------
-- | Assess Service
-- | -----------------------------------------------------------------------
-- | Definition: estimates or validates a learner's knowledge, misconceptions,
-- | or mastery by presenting assessment items selected by the system and
-- | interpreting the learner's responses as evidence about their learning state.
-- |
-- | Because assessment requires two distinct actions (selecting an item, then
-- | interpreting the response), we use two type classes
-- | -----------------------------------------------------------------------

-- | The system selects the most informative assessment item for this learner.

class SelectItem i m item | i m -> item where
  select_item :: i -> m -> item

-- | The system interprets the learner's response as evidence about their
--   knowledge state, producing a mastery estimate or diagnostic result.
class InterpretResponse i m item response mastery | i m item response -> mastery where
  interpret :: i -> m -> item -> response -> mastery

-- | The generic assess function selects an item, obtains the learner's
--   response via a function argument, and interprets that response to
--   produce a mastery result.
--   The (item -> response) argument represents the learner actually
--   responding to the presented item.
assess :: (SelectItem i m item, InterpretResponse i m item response mastery)
       => i -> m -> (item -> response) -> mastery
assess input model get_response =
  let presented_item   = select_item input model       -- Step 1: system selects item
      learner_response = get_response presented_item   -- Step 2: learner responds
  in  interpret input model presented_item learner_response  -- Step 3: system interprets

-- | Runs a fixed number of assessment rounds, returning the mastery estimate
--   after each round.
--   The transition function advances the learner state between rounds
--   (e.g. updating a BKT belief state from the latest mastery estimate).
assess_mastery :: (SelectItem i m item, InterpretResponse i m item response mastery)
               => (i -> mastery -> i)  -- ^ Transition: update learner state from mastery estimate
               -> Int                  -- ^ Number of assessment rounds to run
               -> i -> m -> (item -> response) -> [mastery]
assess_mastery transition n input model get_response =
  take n (iterate_rounds input)
  where
    iterate_rounds i =
      let mastery = assess i model get_response
          i'      = transition i mastery
      in  mastery : iterate_rounds i'

-- | Runs assessment rounds until a mastery criterion is met or a maximum
--   number of rounds is exhausted.
--   Returns the final mastery estimate and the number of rounds taken.
assess_to_criterion :: (SelectItem i m item, InterpretResponse i m item response mastery)
                    => (mastery -> Bool)    -- ^ Criterion: stop when this is satisfied
                    -> (i -> mastery -> i)  -- ^ Transition: update learner state from mastery
                    -> Int                  -- ^ Maximum rounds before stopping regardless
                    -> i -> m -> (item -> response) -> (mastery, Int)
assess_to_criterion met transition max_rounds input model get_response =
  go input 0
  where
    go i n =
      let mastery = assess i model get_response
      in  if met mastery || n + 1 >= max_rounds
            then (mastery, n + 1)
            else go (transition i mastery) (n + 1)
