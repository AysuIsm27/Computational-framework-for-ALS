{-# LANGUAGE FunctionalDependencies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Model
  ( Model (..)
  ) where

-- | Represents a learner model, a peer-learner model, or a combination of
-- both. One class covers all three because they differ in whose data they
-- hold, not in how they behave: each starts empty and is revised by evidence.
--
-- A learner model holds one learner's state: the BKT skill estimates of
-- FeedbackLongAleven, the answer history of ScaffoldImplementations.
--
-- A peer-learner model is built from other learners' data: the item
-- difficulties of AssessPelanek, which every student's answers revise; the
-- grade matrix of the collaborative filtering recommender; the interaction
-- network of HintFactory.
--
-- A combination holds both at once: the MasteryGridsModel of
-- VisualizeBrusilovsky pairs the student's own open learner model with the
-- open social learner model of their peers.
--
-- Which kind each implementation uses is stated in its module header and in
-- the README. Every implementation in this repository declares an instance;
-- that is the sense in which each service is grounded in a model.
--
-- The functional dependency states that the model type determines the type
-- of evidence used to update it.
class Model model evidence | model -> evidence where
  -- | The model before any evidence has been observed.
  initModel :: model

  -- | Revise the model in the light of one new piece of evidence.
  update :: evidence -> model -> model
