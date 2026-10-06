{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
module AssessPelanek where
import Assess
import Model
-- | ---------------------------
-- | Assess Implementation: Pelanek
-- | ---------------------------
-- | Pelanek, R. (2016). Applications of the Elo Rating System in Adaptive Educational
-- | Systems. Computers & Education, 98, 169-179.
-- | https://doi.org/10.1016/j.compedu.2016.03.017
-- |
-- | A student-item answer is treated as a match between the student and the item.
-- | P(correct) = 1 / (1 + e^(-(q_s - d_i)))
-- | After each answer both the student skill q_s and item difficulty d_i are updated:
-- |   q_s := q_s + U(n_s) * (correct - P(correct))
-- |   d_i := d_i - U(n_i) * (correct - P(correct))
-- | where U(n) = a / (1 + b*n) is the uncertainty function (Section 2.3),
-- | with recommended defaults a=1, b=0.05.
-- | The PFAE extension (Section 2.5) uses separate gains g (correct) and d (incorrect)
-- | to distinguish learning from evidence of non-mastery.
-- | Item difficulty d_i is estimated from all previous students' answers (peer data).
data EloModel = EloModel { items     :: [Item]
                         , uncertA   :: Double  -- ^ a in U(n) = a/(1+b*n)
                         , uncertB   :: Double  -- ^ b in U(n) = a/(1+b*n)
                         , gainG     :: Double  -- ^ g: update on correct answer (PFAE)
                         , gainD     :: Double  -- ^ d: update on incorrect answer (PFAE)
                         } deriving (Show)
-- | An item with its Elo difficulty parameter d_i and the number of answers
-- | received so far (used to compute the uncertainty function U(n_i)).
-- | d_i is initialised to 0 and updated from every student's answer (peer data).
data Item = Item { itemId     :: Int
                 , difficulty :: Double  -- ^ d_i: Elo difficulty parameter
                 , numAnswers :: Int     -- ^ n_i: answers received so far
                 } deriving (Show, Eq)
-- | A student with Elo skill parameter q_s and the number of answers given so far.
data Student = Student { studentId :: Int
                       , skill     :: Double  -- ^ q_s: Elo skill parameter
                       , answered  :: Int     -- ^ n_s: answers given so far
                       } deriving (Show, Eq)
data Response = Response { respItem    :: Item
                         , respCorrect :: Bool
                         } deriving (Show, Eq)
-- | Mastery estimate: predicted probability of a correct answer on the next item,
-- | together with the updated student skill q_s.
data MasteryEstimate = MasteryEstimate { predictedProb :: Double
                                       , updatedSkill  :: Double
                                       } deriving (Show, Eq, Ord)
-- | Model instance: the item bank is the peer-learner model. Every student's
-- | answer revises the difficulty d_i of the item they answered, so evidence
-- | from one student informs the assessment of the next.
-- | The uncertainty parameters take the paper's recommended defaults (a=1,
-- | b=0.05); the PFAE gains g and d are fitted to data (Section 2.5).
instance Model EloModel Response where
  initModel = EloModel { items   = []
                       , uncertA = 1.0
                       , uncertB = 0.05
                       , gainG   = 0.1
                       , gainD   = 0.2
                       }
  update    = undefined

-- | SelectItem instance: the system selects the item whose difficulty d_i is
-- | closest to the student's current skill q_s, targeting the configured
-- | success rate (Section 4.1: Outline Maps targets 75% success rate).
instance SelectItem Student EloModel Item where
  select_item student model = undefined
-- | InterpretResponse instance: computes P(correct) from the logistic function,
-- | updates q_s with gain g or d (PFAE, Section 2.5), updates d_i from this
-- | student's answer (peer data accumulates in d_i across all students),
-- | and returns the new mastery estimate.
instance InterpretResponse Student EloModel Item Response MasteryEstimate where
  interpret student model item response = undefined
-- | The (Item -> Response) argument represents the learner
-- | actually responding to the presented item.
service_elo :: Student -> EloModel -> (Item -> Response) -> MasteryEstimate
service_elo = assess
