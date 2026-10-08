{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
module RecommendImplementations where

import Recommend
import Model
import Data.List  (sortBy, sortOn, (\\))
import Data.Maybe (mapMaybe)
import Data.Ord   (comparing, Down(..))
import qualified Data.Map.Strict as Map


-- | =======================================================================
-- | 1. Chen et al. — Item Response Theory (IRT)
-- | =======================================================================
-- | Chen, C. M., Liu, C. Y., & Chang, M. H. (2006).
-- | Personalized curriculum sequencing utilizing modified item response
-- | theory for web-based instruction.
-- | Expert Systems with Applications, 30(2), 378-396.
-- | DOI: https://doi.org/10.1016/j.eswa.2005.07.029
-- | Recommends items whose difficulty best matches the learner's estimated
-- | ability (theta). The learner may choose which item to attempt.

data IRTModel = IRTModel { itemParameters   :: [(Item, IRTParams)]
                         , abilityEstimates :: [(Int, Double)]
                         } deriving (Show)

data IRTParams = IRTParams { difficulty     :: Double  -- b parameter
                           , discrimination :: Double  -- a parameter
                           , guessing       :: Double  -- c parameter
                           } deriving (Show, Eq)

data Item = Item { itemId      :: Int
                 , itemContent :: String
                 } deriving (Show, Eq)

data IRTLearner = IRTLearner { irtStudentId    :: Int
                             , responseHistory :: [(Item, Bool)]
                             } deriving (Show, Eq)

-- Estimates the learner's current ability (theta) from their response history.
estimateAbility    :: IRTLearner -> Double
estimateAbility _  =  undefined

-- Looks up the difficulty parameter for a given item from the IRT model.
itemDifficulty            :: IRTModel -> Item -> Double
itemDifficulty model item  =
  case lookup item (itemParameters model) of
    Just p  -> difficulty p
    Nothing -> 0.0

allItems  :: [Item]
allItems  =  undefined

-- Model: An IRT model is updated by an item response history item.
instance Model IRTModel (Item, Bool) where
  initModel  =  IRTModel [] []
  update  =  undefined

-- Candidates: all items the learner has not yet attempted.
instance Candidates IRTLearner IRTModel Item where
  candidates learner _ =
    let attempted = map fst (responseHistory learner)
    in  allItems \\ attempted

-- Rank: orders candidates by smallest gap between item difficulty and
-- the learner's estimated ability.
rank_irt :: IRTLearner -> IRTModel -> [Item] -> [Item]
rank_irt learner model cs =
  let theta = estimateAbility learner
  in  sortBy (comparing (\c -> abs (itemDifficulty model c - theta))) cs

instance Ranking IRTLearner IRTModel Item where
  rank = rank_irt


service_irt :: IRTLearner -> IRTModel -> [Item]
service_irt learner model = recommend learner model




module PelanekImplementation where

import Recommend
import Model
import qualified Data.Map.Strict as Map

type ActivityId = String

-- Sect. 4.3: Discrete Statuses (Table 3)
-- Abstract performance into discrete classes based on errors, time, and attempts.


data Status 
  = EasyMastery    -- ^ Low error rate, low time to mastery
  | NormalMastery  -- ^ Standard cases of mastery
  | WeakMastery    -- ^ High error rate or high time to mastery
  | Wheelspinning  -- ^ Many attempts, mastery not reached
  | Tried          -- ^ Attempted, mastery not reached, not wheelspinning
  deriving (Show, Eq, Ord, Enum, Bounded)

data PracticeRecord = PracticeRecord
  { practiceActivity :: ActivityId
  , practiceDay      :: Int           -- ^ Day of practice
  , attempts         :: Int           -- ^ Number of attempts
  , errorRate        :: Double        -- ^ Error rate (0.0 - 1.0)
  , timeToMastery    :: Maybe Double  -- ^ Seconds (Nothing if not mastered)
  } deriving (Show, Eq)

-- Configurable performance classification thresholds (Table 3)
data Thresholds = Thresholds
  { lowErrorRate      :: Double
  , highErrorRate     :: Double
  , lowMasteryTime    :: Double
  , highMasteryTime   :: Double
  , wheelspinAttempts :: Int
  } deriving (Show, Eq)

classify :: Thresholds -> PracticeRecord -> Status
classify th r = case timeToMastery r of
  Just t
    | errorRate r <= lowErrorRate th && t <= lowMasteryTime th   -> EasyMastery
    | errorRate r >= highErrorRate th || t >= highMasteryTime th -> WeakMastery
    | otherwise                                                  -> NormalMastery
  Nothing
    | attempts r >= wheelspinAttempts th -> Wheelspinning
    | otherwise                          -> Tried

-- =========================================================================
-- Sect. 4.4 & 4.5: Model Parameters & Context
-- =========================================================================

-- Configurable rule priorities and rule condition thresholds (Table 4)
data RulePriorities = RulePriorities
  { priorityHomework   :: Double
  , priorityFollow     :: Double
  , priorityPred       :: Double
  , priorityRepetition :: Double
  } deriving (Show, Eq)

data RuleParams = RuleParams
  { rulePriorities    :: RulePriorities
  , minRepetitionDays :: Int
  , minHomeworkHour   :: Int
  } deriving (Show, Eq)

data PerformanceModel = PerformanceModel
  { thresholds     :: Thresholds
  , ruleParams     :: RuleParams
  , statuses       :: Map.Map ActivityId (Status, Int) -- ^ Activity -> (Status, Day observed)
  , followUps      :: [(ActivityId, ActivityId)]       -- ^ (B, A): A follows B
  , activityGrades :: Map.Map ActivityId [Int]         -- ^ Activity -> Suitable grade levels
  } deriving (Show)

data RuleContext = RuleContext
  { ctxStudentId :: Int
  , ctxDay       :: Int
  , ctxHour      :: Int           -- ^ Current hour (0-23)
  , ctxHomework  :: [ActivityId]  -- ^ Assigned homework
  , ctxGrade     :: Int           -- ^ Student grade
  } deriving (Show, Eq)

data RuleCandidate = RuleCandidate
  { candActivity :: ActivityId
  , candPriority :: Double        -- ^ Rule priority weight
  , candRule     :: String        -- ^ Rule name/explanation
  } deriving (Show, Eq)


-- Sect. 4.5: Modular Rules (Table 4)
-- IF <condition> THEN recommend activity A with rule priority


rules :: RuleContext -> PerformanceModel -> [RuleCandidate]
rules ctx model =
     [ RuleCandidate a (priorityFollow prio) "Follow topic"
     | (b, (EasyMastery, _)) <- Map.toList st, (b', a) <- followUps model, b' == b ]
  ++ [ RuleCandidate a (priorityPred prio) "Pred topic"
     | (b, (Wheelspinning, _)) <- Map.toList st, (a, b') <- followUps model, b' == b ]
  ++ [ RuleCandidate a (priorityRepetition prio) "Repetition normal"
     | (a, (NormalMastery, day)) <- Map.toList st, ctxDay ctx - day >= minRepetitionDays params ]
  ++ [ RuleCandidate a (priorityHomework prio) "Homework"
     | a <- ctxHomework ctx, ctxHour ctx >= minHomeworkHour params ]
  where
    st     = statuses model
    params = ruleParams model
    prio   = rulePriorities params


-- Sect. 4.6: Postprocessing
-- Filter by student grade and retain highest-priority candidate per activity.


postprocess :: RuleContext -> PerformanceModel -> [RuleCandidate] -> [RuleCandidate]
postprocess ctx model =
  Map.elems . Map.fromListWith higher . map (\c -> (candActivity c, c)) . filter suitable
  where
    suitable c = maybe True (ctxGrade ctx `elem`) (Map.lookup (candActivity c) (activityGrades model))
    higher x y = if candPriority x >= candPriority y then x else y

-- 
-- Sect. 4.7: Roulette-Wheel Selection
-- Priority-weighted sampling without replacement driven by uniform randoms in [0, 1).


rouletteOrder :: [Double] -> [RuleCandidate] -> [RuleCandidate]
rouletteOrder _        [] = []
rouletteOrder []       cs = cs
rouletteOrder (u : us) cs = chosen : rouletteOrder us rest
  where
    totalWeight    = sum (map candPriority cs)
    target         = u * totalWeight
    (chosen, rest) = pick target cs

    pick _ []  = error "rouletteOrder: empty candidate list"
    pick _ [c] = (c, [])
    pick p (c : cs')
      | p < candPriority c = (c, cs')
      | otherwise          = let (x, ys) = pick (p - candPriority c) cs' in (x, c : ys)


-- Framework Instances

instance Model PerformanceModel PracticeRecord where
  initModel = PerformanceModel undefined undefined Map.empty [] Map.empty
  update r model =
    model { statuses = Map.insert (practiceActivity r)
                                  (classify (thresholds model) r, practiceDay r)
                                  (statuses model) }

instance Candidates RuleContext PerformanceModel RuleCandidate where
  candidates ctx model = postprocess ctx model (rules ctx model)               


-- | 3. Rodriguez-Martinez et al. -- Formative Assessment

-- | Rodriguez-Martinez, J. A., Gonzalez-Calero, J. A., del Olmo-Munoz, J.,
-- | Arnau, D., & Tirado-Olivares, S. (2023).
-- | Building personalised homework from a learning analytics based formative
-- | assessment: Effect on fifth-grade students' understanding of fractions.
-- | British Journal of Educational Technology, 54(1), 76-97.
-- | DOI: https://doi.org/10.1111/bjet.13292
-- | Recommends fraction tasks ranked by weakest skill first, then by
-- | increasing difficulty. The learner may choose which task to attempt.

data FormativeModel = FormativeModel { taskBank        :: [FractionTask]
                                     , performanceData :: [(Int, [TaskResult])]
                                     } deriving (Show)

data FractionTask = FractionTask { taskId         :: Int
                                 , taskSkill      :: FractionSkill
                                 , taskDifficulty :: Int
                                 } deriving (Show, Eq)

data FractionSkill = AddFractions
                   | SubtractFractions
                   | MultiplyFractions
                   | DivideFractions
                   | CompareFractions
                   | SimplifyFractions
                   deriving (Show, Eq, Ord, Enum, Bounded)

data TaskResult = TaskResult { resultTaskId :: Int
                             , correct      :: Bool
                             , timeSpent    :: Double
                             } deriving (Show, Eq)

data FormativeLearner = FormativeLearner { formativeStudentId :: Int
                                         , taskHistory        :: [TaskResult]
                                         } deriving (Show, Eq)

-- Computes mastery score for a given fraction skill from the learner's history.
skillMastery                      :: FormativeModel -> FormativeLearner -> FractionSkill -> Double
skillMastery model learner skill  =
  let relevantIds  = [ taskId t | t <- taskBank model, taskSkill t == skill ]
      results      = [ r | r <- taskHistory learner, resultTaskId r `elem` relevantIds ]
      correctCount = length (filter correct results)
  in  if null results then 0.0 else fromIntegral correctCount / fromIntegral (length results)

-- Model: A formative model is updated by task performance results.
instance Model FormativeModel TaskResult where
  initModel  =  FormativeModel [] []
  update  =  undefined

-- Candidates: all tasks the learner has not yet attempted.
instance Candidates FormativeLearner FormativeModel FractionTask where
  candidates learner model =
    let attempted = map resultTaskId (taskHistory learner)
    in  filter (\t -> taskId t `notElem` attempted) (taskBank model)

-- Rank: prioritises tasks targeting the learner's weakest skill, then
-- orders by increasing difficulty within that skill.
rank_formative :: FormativeLearner -> FormativeModel -> [FractionTask] -> [FractionTask]
rank_formative learner model cs =
  sortOn (\t -> (skillMastery model learner (taskSkill t), taskDifficulty t)) cs

instance Ranking FormativeLearner FormativeModel FractionTask where
  rank = rank_formative


service_formative :: FormativeLearner -> FormativeModel -> [FractionTask]
service_formative learner model = recommend learner model





-- | 4. Nguyen et al. -- User-Based Collaborative Filtering

-- | Nguyen, V. A., Nguyen, H. H., Nguyen, D. L., & Le, M. D. (2021).
-- | A course recommendation model for students based on learning outcome.
-- | Education and Information Technologies, 26(5), 5389-5415.
-- | DOI: https://doi.org/10.1007/s10639-021-10524-0
-- |
-- | Predicts grades for courses the learner has not completed using
-- | user-based collaborative filtering and ranks courses by predicted grade.

type StudentId = String
type CourseId  = String
type Grade     = Double
type Row       = Map.Map CourseId Grade

newtype Course = Course
  { courseId :: CourseId
  } deriving (Show, Eq)

data Student = Student
  { studentId        :: StudentId
  , grades           :: Row
  , completedCourses :: [CourseId]
  } deriving (Show, Eq)

data CourseGrade =
  CourseGrade StudentId CourseId Grade
  deriving (Show, Eq)

data CFModel = CFModel
  { program     :: [Course]
  , gradeMatrix :: Map.Map StudentId Row
  } deriving (Show)


-- Model: stores the student-course grade matrix.
instance Model CFModel CourseGrade where
  initModel =
    CFModel [] Map.empty

  update (CourseGrade s c g) model =
    model
      { gradeMatrix =
          Map.insertWith Map.union
            s
            (Map.singleton c g)
            (gradeMatrix model)
      }


-- Candidates: courses the learner has not already completed.
instance Candidates Student CFModel Course where
  candidates student model =
    filter
      ((`notElem` completedCourses student) . courseId)
      (program model)


-- Rank: courses with the highest predicted grades come first.
instance Ranking Student CFModel Course where
  rank student model =
    map fst
      . sortOn (Down . snd)
      . mapMaybe score
    where
      score course =
        fmap ((,) course) (predictGrade student model course)


-- Nguyen et al., Eq. (3): user-based CF grade prediction.
predictGrade :: Student -> CFModel -> Course -> Maybe Grade
predictGrade student model course = do
  meanA <- rowMean rowA

  let terms =
        mapMaybe contribution peerRows

      denominator =
        sum (map fst terms)

  if denominator == 0
    then Nothing
    else Just
      (meanA
       + sum [sim * deviation | (sim, deviation) <- terms]
         / denominator)

  where
    rowA =
      grades student

    courseIds =
      map courseId (program model)

    peerRows =
      Map.elems
        (Map.delete
          (studentId student)
          (gradeMatrix model))

    contribution rowB = do
      gradeBC <- Map.lookup (courseId course) rowB
      meanB   <- rowMean rowB
      sim     <- cosine courseIds rowA rowB

      if sim == 0
        then Nothing
        else Just (sim, gradeBC - meanB)


-- Nguyen et al., Eq. (1): cosine similarity with row-average filling.
cosine :: [CourseId] -> Row -> Row -> Maybe Double
cosine courses rowA rowB = do
  meanA <- rowMean rowA
  meanB <- rowMean rowB

  let xs =
        [ Map.findWithDefault meanA c rowA
        | c <- courses
        ]

      ys =
        [ Map.findWithDefault meanB c rowB
        | c <- courses
        ]

      denominator =
        sqrt
          (sum [x * x | x <- xs]
           * sum [y * y | y <- ys])

  if denominator == 0
    then Nothing
    else Just
      (sum (zipWith (*) xs ys) / denominator)


rowMean :: Row -> Maybe Grade
rowMean row
  | Map.null row =
      Nothing

  | otherwise =
      Just
        (sum (Map.elems row)
         / fromIntegral (Map.size row))


-- Recommend the top n courses.
service_cf :: Int -> Student -> CFModel -> [Course]
service_cf n student model =
  take (max 0 n) (recommend student model)
