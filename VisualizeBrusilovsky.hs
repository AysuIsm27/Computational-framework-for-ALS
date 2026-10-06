{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
module VisualizeBrusilovsky where

import Model
import Visualize

-- | ---------------------------
-- | Visualize Implementation: Brusilovsky et al. (2016)
-- | ---------------------------
-- | Open Social Student Modeling (OSSM) for Personalized Learning.
-- | MasteryGrids: visualizes the student's own knowledge state (OLM)
-- | alongside peer models and a class aggregate model (OSLM),
-- | supporting self-regulated learning via social comparison theory.
-- |
-- | Brusilovsky, P., Somyürek, S., Guerra, J., Hosseini, R.,
-- | Zadorozhny, V., & Durlach, P.J. (2016).
-- | Open Social Student Modeling for Personalized Learning.
-- | IEEE Transactions on Emerging Topics in Computing, 4(3), 450–461.
-- | DOI:10.1109/TETC.2015.2501243

-- | A topic in the domain model (e.g. a Java programming concept).
newtype Topic = Topic { topicName :: String } deriving (Show, Eq, Ord)

-- | A single practice activity attempt by a student on a topic.
-- | The raw interaction data from which the learner model is built.
data ActivityAttempt = ActivityAttempt
  { attemptStudentId :: String
  , attemptTopic     :: Topic
  , attemptSuccess   :: Bool    -- ^ whether the attempt was correct
  , attemptTimestamp :: Double  -- ^ time of attempt
  } deriving (Show, Eq)

-- | Individual Open Learner Model (OLM): the student's own knowledge
-- | state as a mastery level per topic, derived from practice activity logs.
-- | Visualized as a grid of topic-level mastery bars for the student.
data LearnerModel = LearnerModel
  { lmStudentId :: String
  , topicMastery :: [(Topic, Double)]  -- ^ topic -> mastery level in [0,1]
  } deriving (Show, Eq)

-- | Open Social Learner Model (OSLM): the peer-level and class-level
-- | aggregate model used for social comparison.
-- | Exposes peer models and the class average per topic.
data SocialLearnerModel = SocialLearnerModel
  { peerModels   :: [LearnerModel]      -- ^ individual peer models
  , classAverage :: [(Topic, Double)]   -- ^ class aggregate mastery per topic
  } deriving (Show, Eq)

-- | The combined model passed to the visualization service:
-- | the student's own OLM together with the social OSLM.
data MasteryGridsModel = MasteryGridsModel
  { ownModel    :: LearnerModel       -- ^ student's individual OLM
  , socialModel :: SocialLearnerModel -- ^ peer models + class average (OSLM)
  } deriving (Show, Eq)

-- | Model instance: MasteryGrids is grounded in a learner model and a
-- | peer-learner model at once, so both are updated from the same evidence.
-- | A practice attempt is routed by attemptStudentId: the student's own
-- | attempts revise ownModel (the OLM), a peer's attempts revise that peer's
-- | entry in socialModel and the class average (the OSLM).
instance Model MasteryGridsModel ActivityAttempt where
  initModel = MasteryGridsModel
    { ownModel    = LearnerModel { lmStudentId = "", topicMastery = [] }
    , socialModel = SocialLearnerModel { peerModels = [], classAverage = [] }
    }
  update    = undefined

-- | Input: the student's practice activity log used to update the learner model.
data StudentInput = StudentInput
  { inputStudentId :: String
  , activityLog    :: [ActivityAttempt]  -- ^ raw practice attempts
  } deriving (Show, Eq)

-- | MasteryGrids dashboard output: the visual representation of
-- | the student's own OLM alongside peer and class comparisons (OSLM).
data MasteryGridsDashboard = MasteryGridsDashboard
  { selfMasteryGrid  :: [(Topic, Double)]          -- ^ student's own mastery per topic
  , peerMasteryGrids :: [(String, [(Topic, Double)])] -- ^ per-peer mastery grids
  , classAverageGrid :: [(Topic, Double)]           -- ^ class average mastery per topic
  } deriving (Show, Eq)

-- | RenderVisualization instance: combines the student's OLM with the
-- | social OSLM to render the MasteryGrids dashboard.
-- | Shows self mastery, peer mastery, and class average per topic.
instance RenderVisualization StudentInput MasteryGridsModel MasteryGridsDashboard where
  render input model = undefined

service_mastery_grids :: StudentInput -> MasteryGridsModel -> MasteryGridsDashboard
service_mastery_grids = visualize
