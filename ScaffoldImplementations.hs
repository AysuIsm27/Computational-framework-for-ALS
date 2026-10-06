{-# LANGUAGE FlexibleInstances #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module ScaffoldImplementations where

import Model
import Scaffold


first :: [a] -> Maybe a
first (value : _) = Just value
first [] = Nothing


maybe_to_list :: Maybe a -> [a]
maybe_to_list (Just value) = [value]
maybe_to_list Nothing = []


-- | =======================================================================
-- | 1. Razzaq & Heffernan -- Task Decomposition
-- | =======================================================================
-- | Razzaq, L., & Heffernan, N. T. (2006).
-- | Scaffolding vs. Hints in the Assistment System.
-- |
-- | After an incorrect response, the scaffold condition asks authored
-- | subquestions. The hint condition provides equivalent information on
-- | request.

data SupportCondition
  = ScaffoldCondition
  | HintCondition
  deriving (Eq, Show)


data Item = Item
  { itemId :: Int
  , itemText :: String
  , itemHints :: [String]
  } deriving (Eq, Show)


data Answer = Answer
  { answeredItem :: Int
  , answerCorrect :: Bool
  } deriving (Eq, Show)


data DecompositionTask = DecompositionTask
  { currentItem :: Item
  , subItems :: [Item]
  , supportCondition :: SupportCondition
  , hintRequested :: Bool
  , taskMessages :: [String]
  } deriving (Eq, Show)


data DecompositionModel = DecompositionModel
  { answerHistory :: [Answer]
  } deriving (Show)


data DecompositionSupport
  = SubItem Item
  | Hint String
  deriving (Eq, Show)


instance Model DecompositionModel Answer where
  initModel =
    DecompositionModel []

  update answer model =
    model { answerHistory = answer : answerHistory model }


latestAnswer :: Item -> DecompositionModel -> Maybe Answer
latestAnswer item model =
  first
    [ answer
    | answer <- answerHistory model
    , answeredItem answer == itemId item
    ]


instance
  AvailableScaffolds
    DecompositionTask
    DecompositionModel
    DecompositionSupport
  where
  available_scaffolds task _ =
    case supportCondition task of
      ScaffoldCondition ->
        [ SubItem item | item <- subItems task ]
      HintCondition ->
        [ Hint text | text <- itemHints (currentItem task) ]


select_decomposition_support
  :: DecompositionTask
  -> DecompositionModel
  -> [DecompositionSupport]
  -> Maybe DecompositionSupport
select_decomposition_support task model available =
  case latestAnswer (currentItem task) model of
    Just answer
      | not (answerCorrect answer) ->
          case supportCondition task of
            ScaffoldCondition ->
              first
                [ support
                | support@(SubItem _) <- available
                ]
            HintCondition
              | hintRequested task ->
                  first
                    [ support
                    | support@(Hint _) <- available
                    ]
              | otherwise ->
                  Nothing
    _ ->
      Nothing


apply_decomposition_support
  :: DecompositionSupport
  -> DecompositionTask
  -> DecompositionTask
apply_decomposition_support (SubItem item) task =
  task
    { currentItem = item
    , subItems = filter (/= item) (subItems task)
    , hintRequested = False
    }

apply_decomposition_support (Hint text) task =
  task
    { taskMessages = taskMessages task ++ [text]
    , hintRequested = False
    }


service_decomposition
  :: DecompositionTask
  -> DecompositionModel
  -> DecompositionTask
service_decomposition task model =
  scaffold
    select_decomposition_support
    apply_decomposition_support
    task
    model


-- | =======================================================================
-- | 2. Sao Pedro et al. -- Scaffold-aware BKT
-- | =======================================================================
-- | Sao Pedro, M., Baker, R., & Gobert, J. (2013).
-- | Incorporating Scaffolding and Tutor Context into Bayesian Knowledge
-- | Tracing to Predict Inquiry Skill Acquisition.
-- |
-- | The inquiry-skill detector determines when support is available. The
-- | learner-model update records whether scaffolding occurred and the tutor
-- | context in which the skill was demonstrated.

type Skill = String


data Topic
  = PhaseChange
  | FreeFall
  deriving (Eq, Show)


data InquiryTask = InquiryTask
  { inquirySkill :: Skill
  , skillDemonstrated :: Bool
  , supportEnabled :: Bool
  , scaffoldMessage :: String
  , agentMessages :: [String]
  } deriving (Eq, Show)


data Opportunity = Opportunity
  { opportunitySkill :: Skill
  , opportunityShown :: Bool
  , opportunityScaffolded :: Bool
  , opportunityTopic :: Topic
  , opportunityTopicSwitch :: Bool
  } deriving (Eq, Show)


data InquiryModel = InquiryModel
  { masteryEstimates :: [(Skill, Double)]
  } deriving (Show)


newtype AgentTurn = AgentTurn
  { turnText :: String
  } deriving (Eq, Show)


-- Updates the learner model using the paper's scaffold- and
-- context-conditioned BKT model.
updateExtendedBKT :: Opportunity -> InquiryModel -> InquiryModel
updateExtendedBKT = undefined


instance Model InquiryModel Opportunity where
  initModel =
    InquiryModel []

  update =
    updateExtendedBKT


instance AvailableScaffolds InquiryTask InquiryModel AgentTurn where
  available_scaffolds task _
    | supportEnabled task && not (skillDemonstrated task) =
        [AgentTurn (scaffoldMessage task)]
    | otherwise =
        []


select_inquiry_support
  :: InquiryTask
  -> InquiryModel
  -> [AgentTurn]
  -> Maybe AgentTurn
select_inquiry_support _ _ =
  first


apply_inquiry_support :: AgentTurn -> InquiryTask -> InquiryTask
apply_inquiry_support turn task =
  task
    { agentMessages =
        agentMessages task ++ [turnText turn]
    }


service_inquiry :: InquiryTask -> InquiryModel -> InquiryTask
service_inquiry task model =
  scaffold
    select_inquiry_support
    apply_inquiry_support
    task
    model


-- | =======================================================================
-- | 3. Wambsganss et al. -- Dialog Scaffolding
-- | =======================================================================
-- | Wambsganss, T., Kueng, T., Soellner, M., & Leimeister, J. M. (2021).
-- | ArgueTutor: An Adaptive Dialog-Based Learning System for
-- | Argumentation Skills.
-- |
-- | A trained argument-mining model identifies claims and premises. Adaptive
-- | feedback and dialog responses become candidate scaffolds.

data ArgumentLabel
  = Claim
  | Premise
  | NonArgumentative
  deriving (Eq, Show)


data Segment = Segment
  { segmentText :: String
  , segmentLabel :: ArgumentLabel
  } deriving (Eq, Show)


newtype Revision = Revision String
  deriving (Eq, Show)


data DialogModel = DialogModel
  { learnerSegments :: [Segment]
  } deriving (Show)


data DialogTask = DialogTask
  { learnerText :: String
  , learnerUtterance :: String
  , dialogMessages :: [String]
  } deriving (Eq, Show)


data DialogSupport
  = ArgumentFeedback String
  | Theory String
  | DialogResponse String
  deriving (Eq, Show)


-- Analyses argumentative text using the trained argument-mining model.
analyseArgument :: String -> [Segment]
analyseArgument = undefined


-- Produces adaptive feedback from the classified argument components.
argumentFeedback :: DialogModel -> [DialogSupport]
argumentFeedback = undefined


-- Produces a response using the trained dialog-intent model.
dialogResponse :: String -> Maybe DialogSupport
dialogResponse = undefined


instance Model DialogModel Revision where
  initModel =
    DialogModel []

  update (Revision text) model =
    model { learnerSegments = analyseArgument text }


instance AvailableScaffolds DialogTask DialogModel DialogSupport where
  available_scaffolds task model =
    argumentFeedback model
      ++ maybe_to_list (dialogResponse (learnerUtterance task))


select_dialog_support
  :: DialogTask
  -> DialogModel
  -> [DialogSupport]
  -> Maybe DialogSupport
select_dialog_support _ _ =
  first


apply_dialog_support :: DialogSupport -> DialogTask -> DialogTask
apply_dialog_support support task =
  task
    { dialogMessages =
        dialogMessages task ++ [render support]
    }
  where
    render (ArgumentFeedback text) = text
    render (Theory text) = text
    render (DialogResponse text) = text


service_dialog :: DialogTask -> DialogModel -> DialogTask
service_dialog task model =
  scaffold
    select_dialog_support
    apply_dialog_support
    task
    model
