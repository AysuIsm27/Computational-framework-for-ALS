{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
module AssessLimEtAl where
import Assess
import Model
-- | ---------------------------
-- | Assess Implementation: Lim et al.
-- | ---------------------------
-- | Lim, T., Gottipati, S., Cheong, M., Pang, C., & Ng, J. W. (2022). Assessment Design for
-- | Digital Education: An Analytics-based Authentic Assessment Approach. 2022 IEEE
-- | International Conference on Teaching, Assessment and Learning for Engineering (TALE),
-- | pp. 341-348. https://doi.org/10.1109/TALE54877.2022.00063
-- | Gamified Heutagogical Multi-Modal AI-driven (GHMA) Assessment Model.
-- | The learner self-selects a challenge from the available non-linear learning paths.
-- | The response is interpreted as evidence about the learner's mastery state.


data GHMAModel = GHMAModel { gamificationElements :: [(String, Int)]
                           , learningPaths        :: [(String, [AssessmentChallenge])]
                           , allowedTools         :: [Modality]
                           , pastData             :: [(Int, [Double])]
                           } deriving (Show)
data Modality = Video | LivePresentation | WebPublication | Report | RolePlay
                deriving (Show, Eq)
data Learner = Learner { learnerId :: Int
                       , skills    :: [String]
                       } deriving (Show, Eq)
data AssessmentChallenge = AssessmentChallenge { challengeId :: Int
                                               , difficulty  :: Int
                                               , modality    :: Modality
                                               } deriving (Show, Eq)
data LearnerResponse = LearnerResponse { responseLearnerId  :: Int
                                       , attemptedChallenge :: AssessmentChallenge
                                       , createdWork        :: Modality
                                       , trackingData       :: [Double]
                                       } deriving (Show, Eq)
data AssessmentResult = AssessmentResult { masteryEstimate :: Double
                                         , diagnosticInfo  :: String
                                         } deriving (Show, Eq, Ord)
-- Model instance: the learning analytics record (pastData) accumulates the
-- tracking data of each submitted artefact, which is what the model learns from.
instance Model GHMAModel LearnerResponse where
  initModel = GHMAModel { gamificationElements = []
                        , learningPaths        = []
                        , allowedTools         = []
                        , pastData             = []
                        }
  update    = undefined
-- SelectItem instance: the learner self-selects a challenge from the available non-linear learning paths, exercising heutagogical freedom-of-choice.
instance SelectItem Learner GHMAModel AssessmentChallenge where
  select_item learner model  =  undefined
-- InterpretResponse instance: interprets the learner's response as evidence about their mastery state, returning a mastery estimate and diagnostic info.
instance InterpretResponse Learner GHMAModel AssessmentChallenge LearnerResponse AssessmentResult where
  interpret learner model item response  =  undefined
-- The (AssessmentChallenge -> LearnerResponse) argument represents the
-- learner actually responding to the presented challenge.
service_ghma  :: Learner -> GHMAModel -> (AssessmentChallenge -> LearnerResponse) -> AssessmentResult
service_ghma  =  assess
