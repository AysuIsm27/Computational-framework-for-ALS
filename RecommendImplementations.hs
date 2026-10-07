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


-- | =======================================================================
-- | 2. Pelanek et al. -- Rule-based recommendations
-- | =======================================================================
-- | Pelanek, R., Effenberger, T., & Jarusek, P. (2024).
-- | Personalized recommendations for learning activities in online
-- | environments: a modular rule-based approach.
-- | User Modeling and User-Adapted Interaction, 34(4), 1399-1430.
-- | DOI: https://doi.org/10.1007/s11257-024-09396-z
-- | Recommends learning activities in the Umime adaptive practice environment.
-- | Observed performance (errors, attempts, time to mastery) is abstracted
-- | into a discrete status per activity (Sect. 4.3, Table 3). IF-THEN rules
-- | over these statuses, domain relations and context propose activities,
-- | each with the priority and name of its rule (Sect. 4.5-4.6, Table 4).
-- | The candidates are post-filtered, e.g. by the student's grade
-- | (Sect. 4.6), and a batch is presented using a variant of roulette-wheel
-- | selection on the rule priorities (Sect. 4.7). The learner chooses which
-- | recommended activity to practise.
-- |
-- | The paper leaves some details open; the choices made here are:
-- |   * numeric thresholds for the status classes (Table 3 is qualitative);
-- |   * "mastered B well" in the Follow-topic rule is read as Easy mastery;
-- |   * an activity proposed by several rules keeps its highest priority;
-- |   * the roulette-wheel variant is priority-weighted sampling without
-- |     replacement, driven by a seed in the input.

type ActivityId = String

-- | Status classes of Table 3.
data Status = EasyMastery    -- ^ low error rate and low time to mastery
            | NormalMastery  -- ^ other cases of mastery
            | WeakMastery    -- ^ high error rate or high time to mastery
            | Wheelspinning  -- ^ many attempts, mastery not reached
            | Tried          -- ^ mastery not reached, not wheelspinning
            deriving (Show, Eq, Ord, Enum, Bounded)

-- | Evidence: one student's practice of a learning activity.
data PracticeRecord = PracticeRecord
  { practiceActivity :: ActivityId
  , practiceDay      :: Int           -- ^ day of the practice
  , attempts         :: Int           -- ^ number of answers given
  , errorRate        :: Double        -- ^ proportion of incorrect answers
  , timeToMastery    :: Maybe Double  -- ^ seconds; Nothing if not mastered
  } deriving (Show, Eq)

-- | Thresholds for the status classes.
data Thresholds = Thresholds
  { lowErrorRate      :: Double
  , highErrorRate     :: Double
  , lowMasteryTime    :: Double
  , highMasteryTime   :: Double
  , wheelspinAttempts :: Int
  } deriving (Show)

-- | Student performance classification (Sect. 4.3, Table 3).
classify :: Thresholds -> PracticeRecord -> Status
classify th r = case timeToMastery r of
  Just t
    | errorRate r <= lowErrorRate th && t <= lowMasteryTime th  -> EasyMastery
    | errorRate r >= highErrorRate th || t >= highMasteryTime th -> WeakMastery
    | otherwise                                                  -> NormalMastery
  Nothing
    | attempts r >= wheelspinAttempts th -> Wheelspinning
    | otherwise                          -> Tried

-- | Learner model: the latest status per activity and the day it was
-- | observed, together with the domain data the rules use (Sect. 4.4).
data PerformanceModel = PerformanceModel
  { thresholds     :: Thresholds
  , statuses       :: Map.Map ActivityId (Status, Int)
  , followUps      :: [(ActivityId, ActivityId)]  -- ^ (B, A): A typically follows B
  , activityGrades :: Map.Map ActivityId [Int]    -- ^ grades an activity suits
  } deriving (Show)

-- | Input: the student and the context of the recommendation request.
data RuleContext = RuleContext
  { ctxStudentId :: Int
  , ctxDay       :: Int
  , ctxHour      :: Int           -- ^ current hour of the day (0-23)
  , ctxHomework  :: [ActivityId]  -- ^ activities assigned as homework
  , ctxGrade     :: Int
  , ctxSeed      :: Int           -- ^ seed for roulette-wheel selection
  } deriving (Show, Eq)

-- | A recommendation candidate: an activity with the priority and the name
-- | of the rule that generated it (Sect. 4.6). The rule name can be shown
-- | to the student as the reason for the recommendation (Sect. 4.7).
data RuleCandidate = RuleCandidate
  { candActivity :: ActivityId
  , candPriority :: Double
  , candRule     :: String
  } deriving (Show, Eq)

-- | The rules of Table 4: IF condition THEN recommend activity A.
rules :: RuleContext -> PerformanceModel -> [RuleCandidate]
rules ctx model =
     [ RuleCandidate a 0.9 "Follow topic"       -- s mastered B well, (B, A) in follow
     | (b, EasyMastery) <- current, (b', a) <- followUps model, b' == b ]
  ++ [ RuleCandidate a 0.8 "Pred topic"         -- s wheelspinning B, (A, B) in follow
     | (b, Wheelspinning) <- current, (a, b') <- followUps model, b' == b ]
  ++ [ RuleCandidate a 0.5 "Repetition normal"  -- s mastered A normally, >= 10 days ago
     | (a, (NormalMastery, day)) <- Map.toList (statuses model), ctxDay ctx - day >= 10 ]
  ++ [ RuleCandidate a 1.0 "Homework"           -- s has homework A, current time > 2PM
     | a <- ctxHomework ctx, ctxHour ctx >= 14 ]
  where
    current = [ (a, s) | (a, (s, _)) <- Map.toList (statuses model) ]

-- | Postprocessing (Sect. 4.6): keep activities suitable for the student's
-- | grade, and one candidate per activity (the highest-priority one).
postprocess :: RuleContext -> PerformanceModel -> [RuleCandidate] -> [RuleCandidate]
postprocess ctx model =
  Map.elems . Map.fromListWith higher . map (\c -> (candActivity c, c)) . filter suitable
  where
    suitable c = maybe True (ctxGrade ctx `elem`)
                       (Map.lookup (candActivity c) (activityGrades model))
    higher x y = if candPriority x >= candPriority y then x else y

-- | Roulette-wheel ordering (Sect. 4.7): candidates are drawn one by one
-- | with probability proportional to their priority, so high-priority
-- | recommendations tend to come first while the batch stays diverse.
rouletteOrder :: Int -> [RuleCandidate] -> [RuleCandidate]
rouletteOrder _    [] = []
rouletteOrder seed cs = chosen : rouletteOrder seed' rest
  where
    seed'          = (seed * 1103515245 + 12345) `mod` 2147483648
    point          = fromIntegral seed' / 2147483648 * sum (map candPriority cs)
    (chosen, rest) = pick point cs
    pick _ []       = error "rouletteOrder: no candidates"
    pick _ [c]      = (c, [])
    pick p (c : more)
      | p < candPriority c = (c, more)
      | otherwise          = let (x, ys) = pick (p - candPriority c) more in (x, c : ys)

-- Model: each practice record updates the student's status for that activity.
instance Model PerformanceModel PracticeRecord where
  initModel  =  PerformanceModel (Thresholds 0.1 0.3 300 900 20) Map.empty [] Map.empty
  update r model =
    model { statuses = Map.insert (practiceActivity r)
                                  (classify (thresholds model) r, practiceDay r)
                                  (statuses model) }

-- Candidates: activities proposed by the rules, after postprocessing.
instance Candidates RuleContext PerformanceModel RuleCandidate where
  candidates ctx model = postprocess ctx model (rules ctx model)

-- Rank: roulette-wheel ordering on rule priorities.
instance Ranking RuleContext PerformanceModel RuleCandidate where
  rank ctx _ = rouletteOrder (ctxSeed ctx)


-- | A batch of n recommendations, from which the student chooses one.
service_rules :: Int -> RuleContext -> PerformanceModel -> [RuleCandidate]
service_rules n ctx model = recommendTopN n ctx model


-- | =======================================================================
-- | 3. Rodriguez-Martinez et al. -- Formative Assessment
-- | =======================================================================
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





-- | =======================================================================
-- | 4. Nguyen et al. -- User-Based Collaborative Filtering
-- | =======================================================================
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
