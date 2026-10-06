{-# LANGUAGE MultiParamTypeClasses, FunctionalDependencies #-}
module Visualize where

-- | -----------------------------------------------------------------------
-- | Visualize Service
-- | -----------------------------------------------------------------------
-- | Definition: visualizes observable results based on learner behaviour,
-- | a learner model, or a peer-learner model. A visualization service shows
-- | learning progress, engagement, collaboration patterns, etc., often using
-- | dashboards, but other means such as reports also occur.
-- |
-- | 'i' is the learner data input (e.g., game traces, activity logs),
-- | 'm' is the model driving the analysis, and 'v' is the visualization output.
-- | -----------------------------------------------------------------------

-- | Transforms a learner data input and a model into a visual output.
class RenderVisualization i m v | i m -> v where
  render :: i -> m -> v

-- | The generic visualize function transforms learner data and a model into
--   a visual output such as a dashboard or report.
visualize :: RenderVisualization i m v => i -> m -> v
visualize = render

-- | Renders a visualization for each learner in a group, returning each
--   input paired with its visualization output.
--   Useful for generating per-student views within a class-level dashboard.
visualize_group :: RenderVisualization i m v => [i] -> m -> [(i, v)]
visualize_group inputs model =
  map (\i -> (i, render i model)) inputs

-- | Renders visualizations for a group and selects those that satisfy a
--   filter predicate on the output (e.g. learners flagged as at-risk).
--   Returns only the (input, visualization) pairs that pass the filter.
visualize_filtered :: RenderVisualization i m v
                   => (v -> Bool)  -- ^ Filter: keep only outputs satisfying this predicate
                   -> [i] -> m -> [(i, v)]
visualize_filtered keep inputs model =
  filter (keep . snd) (visualize_group inputs model)
