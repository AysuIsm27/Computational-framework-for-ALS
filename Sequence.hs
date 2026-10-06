
{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies #-}
module Sequence where

-- | -----------------------------------------------------------------------
-- | Sequence Service
-- | -----------------------------------------------------------------------
-- | Definition: determines a single learning activity to be performed next,
-- | based on learner behaviour, a learner profile, a learner model, and/or
-- | a peer-learner model. Unlike recommend, there is no list of candidates
-- | from which the receiver may choose: the system selects exactly one next
-- | activity and the student is expected to follow it.
-- | -----------------------------------------------------------------------

-- | Maps a learner input and model to exactly one next activity.
--   The learner has no choice in which activity is selected.

data Mandatory a = Mandatory a deriving (Show, Eq)

-- | Maps a learner input and model to exactly one next activity.
--   The learner has no choice in which activity is selected.
class DetermineNext i m a | i m -> a where
  determine_next :: i -> m -> Mandatory a
-- | The generic sequence function maps a learner state and model to the
--   single next activity the learner must perform.
sequence_activity :: DetermineNext i m a => i -> m -> Mandatory a
sequence_activity = determine_next
-- | Generates a learning path of length n by iterating the sequencing rule.
--   The transition function advances the learner state after each activity.
--   Useful for pre-computing a multi-step path or simulating a learner trace.
sequence_path :: DetermineNext i m a
              => (i -> a -> i)  -- ^ Transition: update learner state after completing an activity
              -> Int            -- ^ Number of steps to plan ahead
              -> i -> m -> [Mandatory a]
sequence_path transition n input model =
  take n (iterate_path input)
  where
    iterate_path i =
      let Mandatory a = determine_next i model
          i'          = transition i a
      in  Mandatory a : iterate_path i'
