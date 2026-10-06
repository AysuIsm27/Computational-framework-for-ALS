{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
module PredictAkcapinarEtAl where

import Predict
import Model

-- | ---------------------------
-- | Predict Implementation: Akcapinar et al.
-- | ---------------------------
-- | kNN-based early-warning system using Moodle LMS interaction features.
-- | Best classifier from a comparison of 7 algorithms (NaiveBayes, CART,
-- | RandomForest, SVM, NeuralNet, CN2, kNN). kNN achieved 89% accuracy.
-- | Akçapınar, G., Altun, A., & Aşkar, P. (2019).
-- | Using learning analytics to develop early-warning system for at-risk students.
-- | International Journal of Educational Technology in Higher Education, 16, 40.
-- | DOI: https://doi.org/10.1186/s41239-019-0172-z

data PredictionModel = PredictionModel
  { trainingSet :: [(ActivityLog, Outcome)]  -- ^ (log, actual outcome)
  , kNeighbours :: Int                       -- ^ k in kNN
  } deriving (Show)

-- | Model instance: the training set grows as each cohort completes the
-- | course and its outcomes become known. k is a hyperparameter selected by
-- | cross-validation rather than a learned quantity.
instance Model PredictionModel (ActivityLog, Outcome) where
  initModel = PredictionModel { trainingSet = [], kNeighbours = 1 }
  update    = undefined

data ActivityLog = ActivityLog
  { logStudentId        :: Int
  , totalSessionCount   :: Int  -- ^ total number of login sessions
  , totalSessionTime    :: Int  -- ^ total time spent in environment (minutes)
  , uniqueSessionDays   :: Int  -- ^ distinct days with a login recorded
  , totalVisits         :: Int  -- ^ total visits to learning materials
  , totalPostsCreated   :: Int  -- ^ total number of posts written
  , uniqueDaysPosted    :: Int  -- ^ distinct days on which posts were written
  , tagUsedCount        :: Int  -- ^ tags applied to written posts
  , tagCreatedCount     :: Int  -- ^ new tags created while writing posts
  , responseCreateCount :: Int  -- ^ responses written in the discussion forum
  , questionRatingCount :: Int  -- ^ questions rated in the discussion forum
  } deriving (Show, Eq)


data Outcome = Passed | Failed deriving (Show, Eq)

-- | PredictObservable instance: maps the learner's early-course Moodle
-- | activity log to a predicted pass/fail outcome via kNN, using the 10
-- | features selected by the Gini index (Table 10).
instance PredictObservable ActivityLog PredictionModel Outcome where
  predict_result activity_log model = undefined

predict_kNN :: ActivityLog -> PredictionModel -> Outcome
predict_kNN = predict
