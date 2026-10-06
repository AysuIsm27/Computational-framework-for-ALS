{-# LANGUAGE MultiParamTypeClasses #-}
{-# LANGUAGE FunctionalDependencies #-}

module Hint
  ( GenerateHint (..)
  , hint
  , hint_batch
  , hint_when
  ) where

-- | -----------------------------------------------------------------------
-- | Hint Service
-- | -----------------------------------------------------------------------
-- | Definition: provides guidance on how to progress in a learner's current
-- | task, based on a learner model and/or a peer-learner model.
-- |
-- | A hint may direct attention to relevant information or suggest a concept,
-- | strategy, intermediate goal, or productive next step without necessarily
-- | revealing the complete solution.
-- |
-- | 't' represents the learner's current task state,
-- | 'm' is the learner model, peer-learner model, or combination of models,
-- | and 'h' is the resulting hint.
-- | -----------------------------------------------------------------------

-- | The combination of task-state type and model type determines
-- | the resulting hint type.
class GenerateHint t m h | t m -> h where
  generate_hint :: t -> m -> Maybe h

-- | Maps a task state and learner model to a tailored hint.
hint :: GenerateHint t m h => t -> m -> Maybe h
hint = generate_hint

-- | Generates hints for a batch of task states using the same learner model.
-- | Returns each task state paired with its hint, preserving input order.
hint_batch
  :: GenerateHint t m h
  => [t]
  -> m
  -> [(t, Maybe h)]
hint_batch tasks model =
  map generate tasks
  where
    generate task = (task, generate_hint task model)

-- | Provides a hint only when help is requested or insufficient progress is
-- | detected.
hint_when
  :: GenerateHint t m h
  => (t -> m -> Bool) -- ^ Whether a hint is currently needed
  -> t                -- ^ Current task state
  -> m                -- ^ Learner or peer-learner model
  -> Maybe h
hint_when needs_hint task model
  | needs_hint task model = generate_hint task model
  | otherwise             = Nothing
