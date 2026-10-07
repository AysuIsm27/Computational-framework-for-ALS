# Adaptive Learning Services Prototype (Haskell)

This repository contains a prototype implementation of adaptive learning services,
written in Haskell.

Each file corresponds to an implementation inspired by a specific study in the
literature. Together, they illustrate how visualization, assessment, feedback,
prediction, sequencing, recommendation, hinting, and scaffolding services can be
defined and instantiated using a shared set of generic patterns.

The code is provided as supplementary material for peer review.

---

## Status

The generic services and the data types of each implementation are given in full.
The bodies of the type class instances are left as `undefined`: the purpose of the
code is to show that systems built on very different computational models
instantiate the same service interfaces, not to reproduce the algorithms of the
original papers. Each stub is documented with the mechanism it stands for, and
with the section of the source paper that specifies it.

Everything compiles. Tested with GHC 9.4.7.

```bash
cabal build
```

---

## Learner Model

- **Model.hs**
  Defines the abstraction shared by every service: a model that starts empty and
  is revised by evidence, where the model type determines the type of evidence.
  One class covers learner models, peer-learner models, and combinations of the
  two, since they differ in whose data they hold rather than in how they behave.
  Each of the nine implementation files declares at least one instance, and the
  module header of each states which kind of model it is.

---

## Service Definitions

- **Visualize.hs**
  Defines the generic visualization service. A learner input and a visualization
  model are mapped to a rendered output. Includes a batch variant for rendering
  across a cohort, and a variant that keeps only the outputs satisfying a filter.

- **Assess.hs**
  Defines the generic assessment service as two composed steps: selecting an
  assessment item for the learner, and interpreting the learner's response as
  evidence about their knowledge state. Includes variants for running multiple
  assessment rounds and for stopping when a mastery criterion is met.

- **Feedback.hs**
  Defines the generic feedback service. A student product and an evaluation model
  are mapped to a feedback result. Includes a batch variant for evaluating a set
  of submissions and an iterative variant for refining a product until feedback
  meets a criterion or a round limit is reached.

- **Predict.hs**
  Defines the generic prediction service. A learner input and a predictive model
  are mapped to a predicted outcome. Includes cohort-level variants for group level
  prediction and for flagging at-risk learners.

- **Sequence.hs**
  Defines the generic sequencing service. A learner state and a sequencing model
  are mapped to the next recommended activity. The `Mandatory` wrapper records that
  the learner is given no choice of activity. Includes a variant for generating
  full learning paths.

- **Recommend.hs**
  Defines the generic recommendation service as two composed steps: determining
  the set of eligible items for a learner, and ranking them from most to least
  suitable. The generic function composes both steps to produce an ordered list
  of recommendations. Includes a variant that bounds the length of that list.

- **Hint.hs**
  Defines the generic hint service. A task state and a learner model are mapped to
  guidance on how to progress, where the model has any to give. Includes a batch
  variant and a variant that withholds help until it is requested or insufficient
  progress is detected.

- **Scaffold.hs**
  Defines the generic scaffolding service. Determines the scaffolds available for
  the current task and learner model, selects one if any is needed, and applies it
  to the task. Fading is not a separate operation: it happens over repeated calls,
  as the learner model and task change and no scaffold is selected.

---

## Implementations

- **VisualizeBrusilovsky.hs**
  Implements a visualization service based on the MasteryGrids Open Social Learner
  Modeling system. Renders a dashboard showing a student's own mastery alongside
  peer models and class averages. Demonstrates a visualization service grounded in
  a learner model and a peer-learner model.

- **AssessLimEtAl.hs**
  Implements a Gamified Heutagogical Multi-Modal AI-driven (GHMA) assessment service.
  Learners self-select challenges from gamified non-linear learning paths and create
  individualized multimodal artefacts; learning analytics interpret responses as
  evidence about mastery. Demonstrates an assessment service grounded in a learner
  model.

- **AssessPelanek.hs**
  Implements an assessment service based on the Elo rating system. A student-item
  answer is treated as a match between the student's skill and the item's difficulty,
  and both ratings are updated from the prediction error. Item difficulty accumulates
  evidence from every student who has answered the item. Demonstrates an assessment
  service grounded in a learner model and a peer-learner model.

- **FeedbackLongAleven.hs**
  Implements an open learner model feedback service that scaffolds self-regulated
  learning in an intelligent tutoring system for linear equations. Presents
  self-assessment prompts after each problem, then reveals updated skill bars as
  feedback on self-assessment accuracy, and provides a level-progress summary for
  problem selection. Demonstrates a feedback service grounded in a learner model.

- **PredictAkcapinarEtAl.hs**
  Implements a student performance prediction service using learning analytics data.
  Uses a learner model built from early course activity to predict final outcomes
  and identify students at risk of failure. Demonstrates a prediction service
  grounded in a learner model.

- **SequenceAhmadalievEtAl.hs**
  Implements a learning activity sequencing service based on learner knowledge state.
  Uses a weighted overlay learner model to order instructional content according to
  the student's current mastery level and learning mode. Demonstrates a sequencing
  service grounded in a learner model.

- **RecommendImplementations.hs**
  Implements four recommendation services in a single file, each grounded in a
  different computational model: item response theory (Chen et al.), an LDA user
  interest model (Jiang et al.), formative assessment analytics (Rodriguez-Martinez et al.),
  and collaborative filtering (Nguyen et al.). All four share the same generic
  recommendation interface. Demonstrates recommendation services grounded in
  learner and peer-learner models.

- **HintFactory.hs**
  Implements a data-driven hint service based on the Hint Factory and its HelpNeed
  extension. Historical solution paths form an interaction network from which a
  productive next step is identified for a known state, while a separate predictor
  decides whether the learner needs help at all. Demonstrates a hint service grounded
  in a peer-learner model.

- **ScaffoldImplementations.hs**
  Implements three scaffolding services in a single file, each grounded in a different
  computational model: task decomposition into authored subquestions (Razzaq &
  Heffernan), scaffold- and context-conditioned knowledge tracing for inquiry skills
  (Sao Pedro et al.), and dialog-based scaffolding driven by argument mining
  (Wambsganss et al.). All three share the same generic scaffolding interface.
  Demonstrates scaffolding services grounded in a learner model.

---

## Documentation

- **SEARCH_QUERY.md** — the literature search used to identify publications describing adaptive learning services.
- **REFERENCES.md** — full citations for the papers in the learner modeling services table, organised by service.
- **RECOMMEND_SERVICES.md** — the four recommendation services described in the vocabulary of the generic service: input, model, candidates, and ranking.

---

## License

Apache License 2.0. See `LICENSE`.
