## Adaptive Learning Services

**Chen et al.** present a sequencing service grounded in a modified Item Response Theory (IRT) model. The central objective is to recommend the *optimal* next learning unit, meaning one that balances difficulty and learnability rather than being too easy or overwhelmingly hard.
- **Input:** Student's current ability estimate and descriptive metadata per unit (e.g. difficulty level).
- **Model:** Modified IRT using ability, difficulty, and discrimination values to estimate the challenge level of each unit.
- **Candidates:** Units not yet completed by the student and for which all prerequisite conditions are satisfied.
- **Best:** A ranked list of units ordered by proximity to a target threshold defined within the modified IRT model, prioritising those whose predicted success likelihood best matches the student's current ability level.

---

**Jagan et al.** propose a learner model for personalised e-content generation, applying Latent Dirichlet Allocation (LDA) to interaction data to identify latent behavioural patterns, which are then integrated into a detailed learner profile for subsequent personalisation.
- **Input:** Interaction records and activity data capturing initial characteristics and behavioural evidence.
- **Model:** A Learner Behaviour (LB) model based on LDA that uncovers latent patterns; behavioural topics are combined with a domain ontology to produce processed learner profiles.
- **Candidates:** Content concepts defined in the domain ontology, each evaluated against the learner's behavioural profile.
- **Best:** A ranked list of concepts ordered by descending suitability score relative to the learner's inferred behavioural traits; each concept's associated e-content is returned as output.

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
