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
-- | 2. Jagan et al. -- Latent Dirichlet Allocation (LDA)
-- | =======================================================================
-- | Jagan, A., Nagarajan, V., & Sathiyamurthy, K. (2017).
-- | Latent Dirichlet allocation based behavior identification system
-- | for personalized E-content generation.
-- | DOI: 10.1166/jctn.2016.5956
-- | Recommends resources ranked by topic similarity to the learner's
-- | inferred behavioural topic mixture. The learner may choose which to access.

data LDAModel = LDAModel { topicDistributions :: [[Double]]
                         , numTopics          :: Int
                         } deriving (Show)

data InteractionLog = InteractionLog { logStudentId  :: Int
                                     , logResourceId :: String
                                     , duration      :: Double
                                     , actionType    :: String
                                     } deriving (Show, Eq)

data LDALearner = LDALearner { ldaLearnerId       :: Int
                             , interactionHistory :: [InteractionLog]
                             } deriving (Show, Eq)

data Resource = Resource { resId        :: String
                         , resType      :: String
                         , resTopicDist :: [Double]
                         } deriving (Show, Eq)

-- Infers the learner's topic mixture from their interaction history.
inferTopicMixture               :: LDAModel -> LDALearner -> [Double]
inferTopicMixture model learner  =  undefined

-- Dot product similarity between two topic distributions.
topicSimilarity        :: [Double] -> [Double] -> Double
topicSimilarity xs ys  =  sum (zipWith (*) xs ys)

allResources  :: [Resource]
allResources  =  undefined

-- Model: An LDA model is updated by an interaction log behavior entry.
instance Model LDAModel InteractionLog where
  initModel  =  LDAModel [] 0
  update  =  undefined

-- Candidates: all resources the learner has not yet accessed.
instance Candidates LDALearner LDAModel Resource where
  candidates learner _ =
    let accessed = map logResourceId (interactionHistory learner)
    in  filter (\r -> resId r `notElem` accessed) allResources

-- Rank: orders candidates by topic similarity to the learner's topic mixture.
rank_lda :: LDALearner -> LDAModel -> [Resource] -> [Resource]
rank_lda learner model cs =
  let topicMix = inferTopicMixture model learner
  in  sortBy (comparing (Down . topicSimilarity topicMix . resTopicDist)) cs

instance Ranking LDALearner LDAModel Resource where
  rank = rank_lda


service_lda :: LDALearner -> LDAModel -> [Resource]
service_lda learner model = recommend learner model


-- | =======================================================================
-- | 3. Rodriguez-Martinez et al. -- Formative Assessment
-- | =======================================================================
-- | Rodriguez-Martinez, J. A., Gonzalez-Calero, J. A., del Olmo-Munoz, J.,
-- | Arnau, D., & Tirado-Olivares, S. (2023).
-- | Building personalised homework from a learning analytics based formative
-- | assessment: Effect on fifth-grade students' understanding of fractions.
-- | British Journal of Educational Technology, 54(1), 88-108.
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
