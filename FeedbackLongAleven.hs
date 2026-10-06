{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
module FeedbackLongAleven where

import Feedback
import Model

-- | =======================================================================
-- | Long & Aleven -- Enhancing learning outcomes through self-regulated
-- | learning support with an Open Learner Model
-- | =======================================================================
-- | Long, Y., & Aleven, V. (2017).
-- | Enhancing learning outcomes through self-regulated learning support
-- | with an Open Learner Model.
-- | User Modeling and User-Adapted Interaction, 27(1), 55–88.
-- | DOI: https://doi.org/10.1007/s11257-016-9186-6
-- |
-- | An ITS for linear equations with a redesigned OLM (Skillometer) that
-- | scaffolds Self-Regulated Learning via three sequential self-assessment
-- | prompts at the end of each problem (View-1), a delayed skill-bar reveal
-- | (bars update after prompts so the update gives feedback on accuracy),
-- | and a level-progress summary with shared student/system problem selection
-- | (View-2).  The underlying learner model is Bayesian Knowledge Tracing
-- | (Corbett & Anderson 1994) per KC; mastery is declared at P(Lₙ) ≥ θ.
-- | Two classroom experiments (N = 302, grades 7–8) confirmed a significant
-- | OLM effect on post-test scores (Experiment 1: p = .031, η² = .078).
-- |



-- Domain


-- | Five equation levels (Table 1 in the paper).
data EquationLevel
  = Level1   -- ^ x + 5 = 7           (one step)
  | Level2   -- ^ 2x + 1 = 7          (two steps)
  | Level3   -- ^ 3x + 1 = x + 5      (multiple steps)
  | Level4   -- ^ 2(x + 1) = 8        (parentheses)
  | Level5   -- ^ 2(x + 1) + 1 = 5    (parentheses, harder)
  deriving (Show, Eq, Ord, Enum, Bounded)

newtype KC = KC { kcName :: String } deriving (Show, Eq)

-- | System-wide domain configuration: BKT parameters, mastery threshold,
--   and level-to-KC mapping.
data DomainConfig = DomainConfig
  { bktParamsPerKC   :: [(KC, BKTParams)]
  , masteryThreshold :: Double               -- ^ θ: P(Lₙ) ≥ θ → mastered
  , levelKCMapping   :: [(EquationLevel, [KC])]
  } deriving (Show)


domain_config :: DomainConfig
domain_config = undefined

-- ---------------------------------------------------------------------------
-- BKT (Corbett & Anderson 1994)
-- ---------------------------------------------------------------------------

-- | Four-parameter BKT model per KC.
data BKTParams = BKTParams
  { pL0 :: Double  -- ^ P(L₀):  prior probability of knowing the KC
  , pT  :: Double  -- ^ P(T):   probability of learning on each opportunity
  , pS  :: Double  -- ^ P(S):   slip probability   (correct given known)
  , pG  :: Double  -- ^ P(G):   guess probability  (correct given unknown)
  } deriving (Show)

-- | Running BKT state for one KC.
data SkillState = SkillState
  { kc         :: KC
  , pKnow      :: Double  -- ^ P(Lₙ): current posterior mastery probability
  , attemptLog :: [Bool]  -- ^ step outcomes in order (True = correct)
  } deriving (Show)

-- | One BKT update (Corbett & Anderson 1994, Equations 1–2).
-- | P(Lₙ|correct)   = P(Lₙ)·(1−P(S)) / [P(Lₙ)·(1−P(S)) + (1−P(Lₙ))·P(G)]
-- | P(Lₙ|incorrect) = P(Lₙ)·P(S)     / [P(Lₙ)·P(S)     + (1−P(Lₙ))·(1−P(G))]
-- | P(Lₙ₊₁) = P(Lₙ|obs) + (1 − P(Lₙ|obs)) · P(T)
bktUpdate :: BKTParams -> SkillState -> Bool -> SkillState
bktUpdate _ _ _ = undefined

-- ---------------------------------------------------------------------------
-- Product: what the student produces by completing one problem
-- ---------------------------------------------------------------------------
-- The product consists of the solution steps the student took, the
-- self-assessment responses collected at the end of the problem, and
-- the equation level attempted.

-- | One attempted solution step, tagged with the KC it exercises.
--   Hints and incorrect attempts are tracked separately, as both contribute
--   to the assistance score reported in the paper's log data (Table 3).
data SolutionStep = SolutionStep
  { stepKC            :: KC
  , stepCorrect       :: Bool
  , hintsRequested    :: Int  -- ^ number of hints requested on this step
  , incorrectAttempts :: Int  -- ^ number of incorrect attempts before correct
  } deriving (Show)

-- | Prompt 1: confidence rating on a scale from 1 to 7.
newtype ConfidenceRating = ConfidenceRating { ratingValue :: Int }  -- ^ 1..7
  deriving (Show, Eq)

-- | Prompt 2: student's declared mastery for the current level.
newtype DeclareMastery = DeclareMastery { declaredMastered :: Bool }
  deriving (Show, Eq)

-- | Prompt 3: which KC the student judges to be their least mastered.
newtype LeastMasteredChoice = LeastMasteredChoice { chosenKC :: KC }
  deriving (Show, Eq)

-- | All three self-assessment prompt responses, collected sequentially
--   at the end of each problem.
data SelfAssessment = SelfAssessment
  { confidenceRating    :: ConfidenceRating
  , declareMastery      :: DeclareMastery
  , leastMasteredChoice :: LeastMasteredChoice
  } deriving (Show)

-- | The student product: the level attempted, the solution steps taken,
--   and the self-assessment responses submitted at the end of the problem.
data StudentProduct = StudentProduct
  { productLevel    :: EquationLevel
  , solutionSteps   :: [SolutionStep]
  , selfAssessment  :: SelfAssessment
  } deriving (Show)

-- ---------------------------------------------------------------------------
-- Model: student-specific learner state only
-- ---------------------------------------------------------------------------

-- | Student-specific learner state, updated after each problem.

data LearnerModel = LearnerModel
  { skillStates      :: [SkillState]
  , prevSkillStates  :: [SkillState]
    -- ^ P(Lₙ) values before this problem; for the before/after bar reference
  , priorAssessments :: [SelfAssessment]
    -- ^ all prior self-assessment responses in this session;
    --   for computing accuracy index (Formula 1)
  } deriving (Show)

-- | Model instance: the BKT state is revised after each completed problem.
--   Each solution step is an opportunity for the KC it exercises, and the
--   P(Lₙ) values from before the problem are retained as the bar reference.
instance Model LearnerModel StudentProduct where
  initModel = LearnerModel { skillStates      = []
                           , prevSkillStates  = []
                           , priorAssessments = []
                           }
  update    = undefined

-- ---------------------------------------------------------------------------
-- After all steps are completed, the OLM shows: (1) updated skill bars
-- with a before/after comparison (View-1, revealed after the self-
-- assessment prompts), (2) a level-progress summary with a recommended
-- next level (View-2), and (3) an accuracy index over the session.

-- | One bar in the delayed skill-bar reveal (View-1).
--   Before/after positions shown so the update itself gives feedback.
data SkillBar = SkillBar
  { barKC      :: KC
  , previousP  :: Double  -- ^ P(Lₙ) before this problem (reference line)
  , updatedP   :: Double  -- ^ P(Lₙ) after  this problem (new bar position)
  , isMastered :: Bool    -- ^ updatedP ≥ masteryThreshold
  } deriving (Show)

-- | Level progress entry for View-2.
data LevelProgress = LevelProgress
  { progressLevel  :: EquationLevel
  , problemsSolved :: Int
  , levelMastered  :: Bool  -- ^ all KCs in this level are mastered
  } deriving (Show)

-- | Full OLM feedback returned to the student.
--   View-1: updatedSkillBars (revealed after 1-second delay post prompts).
--   View-2: levelProgressSummary + recommendedLevel for problem selection.
--   accuracyIndex: Absolute Accuracy Index (Formula 1) over session history.
data OLMFeedback = OLMFeedback
  { updatedSkillBars     :: [SkillBar]
  , accuracyIndex        :: Double
    -- ^ (1/N) Σ|c_i − p_i|  (Formula 1 in the paper)
  , levelProgressSummary :: [LevelProgress]
  , recommendedLevel     :: EquationLevel
    -- ^ lowest unmastered level; default in shared-control problem selection
  } deriving (Show)

-- ---------------------------------------------------------------------------
-- Helper functions
-- ---------------------------------------------------------------------------

-- | Absolute Accuracy Index (Formula 1 in the paper).
--   c_i ∈ [1,7] rescaled to [0,1]; p_i = P(Lₙ) ∈ [0,1].
absoluteAccuracyIndex :: [(Double, Double)] -> Double
absoluteAccuracyIndex _ = undefined

-- | Assistance score for a step: (hints + incorrect attempts) / total steps.
--   Used in the paper's log data analysis (Table 3).
assistanceScore :: [SolutionStep] -> Double
assistanceScore _ = undefined

-- | Build a SkillBar from the before/after SkillState pair.
--   Uses domain_config for the mastery threshold.
buildSkillBar :: Double -> Double -> SkillState -> SkillBar
buildSkillBar _ _ _ = undefined

-- | Compute level progress from current skill states (View-2).
--   Takes DomainConfig explicitly so it can be used in tests with
--   configs other than domain_config.
computeLevelProgress :: DomainConfig -> [SkillState] -> [LevelProgress]
computeLevelProgress _ _ = undefined

-- | Select the lowest unmastered level as the system recommendation.
selectRecommendedLevel :: [LevelProgress] -> EquationLevel
selectRecommendedLevel _ = undefined

-- ---------------------------------------------------------------------------
-- EvaluateProduct instance
-- ---------------------------------------------------------------------------

-- | The model argument is LearnerModel (per-student state only).

instance EvaluateProduct StudentProduct LearnerModel OLMFeedback where
  evaluate_product _ _ = undefined

service_olm_feedback :: StudentProduct -> LearnerModel -> OLMFeedback
service_olm_feedback = feedback

-- ---------------------------------------------------------------------------
-- Example data
-- ---------------------------------------------------------------------------

example_bkt_params :: BKTParams
example_bkt_params = undefined

example_learner_model :: LearnerModel
example_learner_model = undefined

example_skill_state :: KC -> SkillState
example_skill_state _ = undefined

example_self_assessment :: SelfAssessment
example_self_assessment = undefined

example_student_product :: StudentProduct
example_student_product = undefined
