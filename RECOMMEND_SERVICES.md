## Adaptive Learning Services

**Chen et al.** present a sequencing service grounded in a modified Item Response Theory (IRT) model. The central objective is to recommend the *optimal* next learning unit, meaning one that balances difficulty and learnability rather than being too easy or overwhelmingly hard.
- **Input:** Student's current ability estimate and descriptive metadata per unit (e.g. difficulty level).
- **Model:** Modified IRT using ability, difficulty, and discrimination values to estimate the challenge level of each unit.
- **Candidates:** Units not yet completed by the student and for which all prerequisite conditions are satisfied.
- **Best:** A ranked list of units ordered by proximity to a target threshold defined within the modified IRT model, prioritising those whose predicted success likelihood best matches the student's current ability level.

---

**Pelánek et al.** present a modular rule-based framework for recommending learning activities, deployed in the Umíme adaptive practice environment used by tens of thousands of students per day. Observed performance is abstracted into discrete status classes, and IF-THEN rules over these statuses, domain relations, and context generate prioritised recommendations, which are shown to the student as a batch to choose from.
- **Input:** Students' practice data per learning activity (correctness of answers, response times, number of attempts), together with context such as assigned homework, the current time, and the student's grade.
- **Model:** A student performance classification that assigns each practised activity a status class (easy mastery, normal mastery, weak mastery, wheelspinning, or tried), combined with domain data such as follow-up relations between topics and the grades for which activities are suitable.
- **Candidates:** Activities proposed by IF-THEN rules, each with a priority and the name of the rule that produced it. Examples from the paper are a follow-up activity after easy mastery (priority 0.9), the preceding topic after wheelspinning (0.8), repetition of an activity mastered normally at least 10 days ago (0.5), and assigned homework in the afternoon (1). Candidates are then post-filtered, for example to activities suitable for the student's grade.
- **Best:** A batch of activities selected by a variant of roulette-wheel selection on rule priorities, which favours high-priority rules while keeping the batch diverse; the student chooses which recommended activity to practise. Our implementation uses priority-weighted sampling without replacement and keeps the highest priority when several rules propose the same activity, as the paper does not fix these details.

---

**Rodríguez-Martínez et al.** present a personalised homework system to improve fifth-grade students' understanding of fractions, integrating formative assessment with learning analytics to adapt practice problems to each student's current needs.
- **Input:** Results from class-based formative assessments via an Audience Response System (ARS), recording responses to fraction tasks and identifying misconceptions or unmastered constructs.
- **Model:** A learning analytics model tracking performance across five fraction constructs (part-whole, ratio, operator, quotient, and measure), representing mastery, non-mastery, and errors.
- **Candidates:** A repository of fraction problems, each tagged to one or more constructs, filtered to those relevant to the student's weak areas after each session.
- **Best:** A ranked list of problems ordered by relevance to the student's current areas of non-mastery, balancing targeting of weak constructs with likely effectiveness.

---

**Nguyen et al.** present a course recommendation service grounded in a peer-learner model, predicting the grade a student would earn in courses they have not yet taken from the records of students with comparable histories.
- **Input:** The student's completed courses and the grades earned in them.
- **Model:** A user-based collaborative filtering model over the student-course grade matrix for the whole programme. The matrix is a peer-learner model: a recommendation for one student is derived from what comparable students went on to achieve.
- **Candidates:** Courses in the programme the student has not already completed.
- **Best:** A ranked list of courses ordered by descending predicted grade, where the prediction adjusts the student's own mean by the similarity-weighted deviations of their peers.
