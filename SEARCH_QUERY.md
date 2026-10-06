**Figure 1.** *Query used to identify publications describing adaptive learning services.*
```
TITLE-ABS-KEY (
  ( "learner model*" OR "student model*" OR "adaptive model*" OR
    "learning analytics" OR "machine learning" )
  AND ( "implementation*" OR "application*" OR "use-case*" OR "service*" )
  AND ( "education" OR "e-learning" OR "adaptive learning" OR
    "intelligent tutoring system*" OR "learning management system*" OR
    "personalized learning" )
)
AND ( LIMIT-TO ( DOCTYPE , "cp" ) OR LIMIT-TO ( DOCTYPE , "ar" ) )
AND ( LIMIT-TO ( LANGUAGE , "English" ) )
```
