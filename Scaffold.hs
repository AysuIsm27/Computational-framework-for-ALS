{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies #-}
module Scaffold
  ( AvailableScaffolds (..)
  , scaffold
  ) where


-- | Represents a learner or peer-learner model.
-- | The model can be updated when new learning data is observed.


-- | Returns the scaffolds that are available for the current task
-- | and learner model.
class AvailableScaffolds t m s | t m -> s where
  available_scaffolds :: t -> m -> [s]


-- | Provides scaffold support for the current task.
--
-- | The first function decides which scaffold, if any, should be given.
-- | The second function applies that scaffold to the task.
--
-- | If no scaffold is needed, the task is returned unchanged.
-- | Fading happens over repeated calls as the learner model and task change.
scaffold :: AvailableScaffolds t m s
         => (t -> m -> [s] -> Maybe s)
         -> (s -> t -> t)
         -> t -> m -> t
scaffold select_scaffold apply_scaffold task model =
  case select_scaffold task model (available_scaffolds task model) of
    Nothing -> task
    Just s  -> apply_scaffold s task
