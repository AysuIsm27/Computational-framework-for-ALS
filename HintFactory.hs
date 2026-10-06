{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module HintFactory where

import Data.Map.Strict (Map)
import qualified Data.Map.Strict as Map

import Hint
import Model


-- | =======================================================================
-- | Maniktala et al. -- Hint Factory and HelpNeed
-- | =======================================================================
-- | Maniktala, M., Cody, C., Isvik, A., Lytle, N., Chi, M., & Barnes, T.
-- | (2020). Extending the Hint Factory for the Assistance Dilemma:
-- | A Novel, Data-driven HelpNeed Predictor for Proactive Problem-solving
-- | Help. Journal of Educational Data Mining, 12(4), 24-65.
-- |
-- | Historical solution paths form an interaction network. Hint Factory
-- | identifies a productive next step for a known state. The proactive policy
-- | separately predicts whether the learner needs help at the start of a step.

type State = String
type Step = String
type FeatureVector = Map String Double


data Transition = Transition
  { transitionFrom :: State
  , transitionStep :: Step
  , transitionTo :: State
  } deriving (Eq, Show)


data Advice = Advice
  { adviceStep :: Step
  , adviceNextState :: State
  } deriving (Eq, Show)


data HelpNeedInput
  = StateBased FeatureVector
  | StateFree FeatureVector
  deriving (Eq, Show)


-- | Represents the fitted state-based and state-free predictors.
-- Their trained Random Forest trees are not specified in the paper.
data HelpNeedPredictor = HelpNeedPredictor
  deriving (Eq, Show)


data HintFactoryModel = HintFactoryModel
  { bestNext :: Map State Advice
  , globalQuality :: Map State Double
  , helpNeedPredictor :: HelpNeedPredictor
  } deriving (Eq, Show)



update_hint_factory
  :: Transition
  -> HintFactoryModel
  -> HintFactoryModel
update_hint_factory = undefined



predict_help_need :: HelpNeedPredictor -> HelpNeedInput -> Bool
predict_help_need = undefined


instance Model HintFactoryModel Transition where
  initModel =
    HintFactoryModel
      { bestNext = Map.empty
      , globalQuality = Map.empty
      , helpNeedPredictor = HelpNeedPredictor
      }

  update =
    update_hint_factory


-- Generates a Hint Factory suggestion for a historically known state.
instance GenerateHint State HintFactoryModel Advice where
  generate_hint state model =
    Map.lookup state (bestNext model)


-- Provides a proactive hint only when the HelpNeed predictor requests one.
proactive_hint
  :: HelpNeedInput
  -> State
  -> HintFactoryModel
  -> Maybe Advice
proactive_hint input state model
  | predict_help_need (helpNeedPredictor model) input =
      hint state model
  | otherwise =
      Nothing


service_hint :: State -> HintFactoryModel -> Maybe Advice
service_hint = hint
