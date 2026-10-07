{-# LANGUAGE MultiParamTypeClasses, FlexibleInstances #-}
module RecommendImplementations where

import Recommend
import Model
import Data.List  (sortBy, sortOn, union, (\\))
import Data.Maybe (mapMaybe)
import Data.Ord   (comparing, Down(..))
import qualified Data.Map.Strict as Map



-- | 1. Chen et al. — Item Response Theory (IRT)

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


-- | 2. Jiang et al. -- LDA user interest model

-- | Jiang, X., Bai, L., Yan, X., & Wang, Y. (2023).
-- | LDA-based online intelligent courses recommendation system.
-- | Evolutionary Intelligence, 16(5), 1619-1625.
-- | DOI: https://doi.org/10.1007/s12065-022-00810-2
-- | An LDA user interest model, trained on learner behaviour data, gives each
-- | learner a preference P(M) for each of their interest topics M (Sect. 3.2).
-- | For each topic, the learner's interest in a course combines that
-- | preference, the similarity between the topic's word distribution and the
-- | course's keyword frequencies (1 / Jensen-Shannon distance), and the
-- | course's importance Q(s), which weighs course quality (normalised number
-- | of user evaluations) against inclusiveness (fit between the course
-- | schedule and the learner's available time) (Eqs. 1-3). Courses are ranked
-- | by interest degree. The learner may choose which course to take.
-- |
-- | The paper leaves three details open; the choices made here are:
-- |   * candidate set: courses the learner has not yet taken;
-- |   * X(a,s): the per-topic values X_M(a,s) are summed over the learner's
-- |     C interest topics (the paper announces but does not give this formula);
-- |   * inclusiveness T(s): 1 if the course schedule differs from the
-- |     learner's available time by less than 6.8% (the threshold the paper
-- |     states), and 0 otherwise.

type Keyword      = String
type Distribution = Map.Map Keyword Double

-- | A latent topic M with its word distribution.
data Topic = Topic { topicId    :: Int
                   , topicWords :: Distribution
                   } deriving (Show)

data LDAModel = LDAModel
  { ldaTopics         :: [Topic]                      -- ^ topic-word distributions
  , userTopicPrefs    :: Map.Map Int [(Int, Double)]  -- ^ learner -> [(topic id, P(M))]
  , courseEvaluations :: Map.Map String Int           -- ^ course -> number of user evaluations
  , topWords          :: Int                          -- ^ j: top words per topic forming K
  , qualityWeight     :: Double                       -- ^ lambda in Eq. (1)
  } deriving (Show)

-- | Learner behaviour evidence: a learner's interaction with a course,
-- | which may include evaluating it.
data InteractionLog = InteractionLog { logStudentId :: Int
                                     , logCourseId  :: String
                                     , evaluated    :: Bool
                                     } deriving (Show, Eq)

data LDALearner = LDALearner { ldaLearnerId       :: Int
                             , interactionHistory :: [InteractionLog]
                             , availableTime      :: Double  -- ^ Ydate
                             } deriving (Show, Eq)

-- | A course, with keyword counts from its name, teacher and introduction
-- | (the keyword set L and frequencies F_s) and its scheduled time Tdate(s).
data OnlineCourse = OnlineCourse { ocId            :: String
                                 , ocKeywordCounts :: Map.Map Keyword Int
                                 , ocScheduledTime :: Double
                                 } deriving (Show, Eq)

courseCatalogue  :: [OnlineCourse]
courseCatalogue  =  undefined

-- | Z(s): course quality, i.e. its number of user evaluations normalised
-- | over the candidate set (Sect. 3.1).
quality :: LDAModel -> [OnlineCourse] -> OnlineCourse -> Double
quality model cs c
  | total == 0 = 0
  | otherwise  = evals c / total
  where
    evals x = fromIntegral (Map.findWithDefault 0 (ocId x) (courseEvaluations model))
    total   = sum (map evals cs)

-- | T(s): inclusiveness of the course schedule for the learner (Sect. 3.1).
inclusiveness :: LDALearner -> OnlineCourse -> Double
inclusiveness learner c
  | ydate /= 0 && abs (ocScheduledTime c - ydate) / abs ydate < 0.068 = 1
  | otherwise                                                       = 0
  where
    ydate = availableTime learner

-- | Q(s) = lambda * Z(s) + (1 - lambda) * T(s)   (Eq. 1)
importance :: LDAModel -> LDALearner -> [OnlineCourse] -> OnlineCourse -> Double
importance model learner cs c =
  lam * quality model cs c + (1 - lam) * inclusiveness learner c
  where
    lam = qualityWeight model

-- | sim(gamma_M, F_s) = 1 / U(gamma_M, F_s), with U the Jensen-Shannon
-- | distance, computed over the combined word set H = L `union` K, where L
-- | holds the course's keywords and K the topic's top-j words (Sect. 3.2, Eq. 2).
topicCourseSimilarity :: Int -> Topic -> OnlineCourse -> Double
topicCourseSimilarity j topic c =
  1 / max 1e-9 (jsDistance gamma freqs)
  where
    kSet  = map fst (take j (sortOn (Down . snd) (Map.toList (topicWords topic))))
    hSet  = Map.keys (ocKeywordCounts c) `union` kSet
    gamma = normalise [ if h `elem` kSet then Map.findWithDefault 0 h (topicWords topic) else 0
                      | h <- hSet ]
    freqs = normalise [ fromIntegral (Map.findWithDefault 0 h (ocKeywordCounts c)) | h <- hSet ]

normalise :: [Double] -> [Double]
normalise xs
  | total == 0 = xs
  | otherwise  = map (/ total) xs
  where
    total = sum xs

-- | Jensen-Shannon distance (square root of the JS divergence, base 2).
jsDistance :: [Double] -> [Double] -> Double
jsDistance p q = sqrt (max 0 (0.5 * kl p mid + 0.5 * kl q mid))
  where
    mid = zipWith (\a b -> (a + b) / 2) p q
    kl xs ys = sum [ x * logBase 2 (x / y) | (x, y) <- zip xs ys, x > 0, y > 0 ]

-- | X(a, s): learner a's interest degree in course s. Per topic M,
-- | X_M(a, s) = P(M) * sim(gamma_M, F_s) * Q(s)   (Eq. 3),
-- | summed over the learner's interest topics.
interestDegree :: LDAModel -> LDALearner -> [OnlineCourse] -> OnlineCourse -> Double
interestDegree model learner cs c =
  sum [ pM * topicCourseSimilarity (topWords model) t c * q
      | (tid, pM) <- Map.findWithDefault [] (ldaLearnerId learner) (userTopicPrefs model)
      , t <- ldaTopics model
      , topicId t == tid ]
  where
    q = importance model learner cs c

-- Model: course evaluations in the learner behaviour data are counted for
-- Z(s). (Re-training the LDA topic model itself is not shown here.)
instance Model LDAModel InteractionLog where
  initModel  =  LDAModel [] Map.empty Map.empty 10 0.5
  update l model
    | evaluated l = model { courseEvaluations =
                              Map.insertWith (+) (logCourseId l) 1 (courseEvaluations model) }
    | otherwise   = model

-- Candidates: courses the learner has not yet taken.
instance Candidates LDALearner LDAModel OnlineCourse where
  candidates learner _ =
    let taken = map logCourseId (interactionHistory learner)
    in  filter (\c -> ocId c `notElem` taken) courseCatalogue

-- Rank: orders candidates by descending interest degree X(a, s).
rank_lda :: LDALearner -> LDAModel -> [OnlineCourse] -> [OnlineCourse]
rank_lda learner model cs =
  sortOn (Down . interestDegree model learner cs) cs

instance Ranking LDALearner LDAModel OnlineCourse where
  rank = rank_lda


service_lda :: LDALearner -> LDAModel -> [OnlineCourse]
service_lda learner model = recommend learner model



-- | 3. Rodriguez-Martinez et al. -- Formative Assessment
-- 
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
