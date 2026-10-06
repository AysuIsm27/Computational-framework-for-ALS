{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies #-}
module Predict where

-- | ---------------------------
-- | General Abstractions
-- | ---------------------------
-- This is a generalized approach to modeling prediction services using type classes.
-- The generic entry point is 'predict', defined below.

-- | PredictObservable is a type class for mapping a learner input and model
-- | to a predicted observable outcome.
-- | An observable result can be a behaviour, performance, outcome, or any
-- | measurable quantity of interest (e.g. pass/fail, test score, dropout).
class PredictObservable i m o | i m -> o where
  predict_result  ::  i -> m -> o

-- | The generic 'predict' function maps a learner input and model to a
-- | predicted observable outcome.
predict              ::  PredictObservable i m o => i -> m -> o
predict input model  =   predict_result input model

-- | Applies the prediction model to every learner in a cohort, returning
-- | each learner paired with their predicted outcome.
predict_cohort                 ::  PredictObservable i m o => [i] -> m -> [(i, o)]
predict_cohort learners model  =   map (\i -> (i, predict_result i model)) learners

-- | Partitions a cohort into at-risk and not-at-risk groups.
-- | The predicate decides whether a predicted outcome counts as at-risk
-- | (e.g. \o -> passProbability o < 0.5).
flag_at_risk                            ::  PredictObservable i m o
                                        =>  (o -> Bool) -> [i] -> m -> ([i], [i])
flag_at_risk is_at_risk learners model  =
  let scored  =  predict_cohort learners model
  in  ( map fst (filter (is_at_risk       . snd) scored)
      , map fst (filter (not . is_at_risk . snd) scored) )
