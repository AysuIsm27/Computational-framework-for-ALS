## Adaptive Learning Services

**Chen et al.** present a sequencing service grounded in a modified Item Response Theory (IRT) model. The central objective is to recommend the *optimal* next learning unit, meaning one that balances difficulty and learnability rather than being too easy or overwhelmingly hard.
- **Input:** Student's current ability estimate and descriptive metadata per unit (e.g. difficulty level).
- **Model:** Modified IRT using ability, difficulty, and discrimination values to estimate the challenge level of each unit.
- **Candidates:** Units not yet completed by the student and for which all prerequisite conditions are satisfied.
- **Best:** A ranked list of units ordered by proximity to a target threshold defined within the modified IRT model, prioritising those whose predicted success likelihood best matches the student's current ability level.

---

**Jiang et al.** present an online course recommendation method based on an LDA (Latent Dirichlet Allocation) user interest model, evaluated on learner behaviour data from the XuetangX online learning platform. The model infers each learner's preferences over latent interest topics and combines them with each course's importance to recommend courses.
- **Input:** Learner behaviour data (used to train the LDA user interest model); course descriptions (course name, teacher, and introduction, segmented into keywords); users' evaluations of courses; course schedules; and the learner's available time.
- **Model:** An LDA user interest model that gives the learner's preference P(M) for each interest topic M and each topic's word distribution, combined with a course importance score Q(s) = λ·Z(s) + (1−λ)·T(s), which weighs course quality Z(s) (the normalised number of user evaluations) against inclusiveness T(s) (how well the course schedule fits the learner's available time).
- **Candidates:** The learner's candidate set of courses. The paper does not specify how this set is formed; our implementation uses the courses the learner has not yet taken.
- **Best:** A ranked list of courses ordered by descending interest degree, where for each topic X_M(a,s) = P(M) · sim(γ_M, F_s) · Q(s), and sim is the inverse Jensen–Shannon distance between the topic's word distribution and the course's keyword frequencies. Our implementation sums X_M(a,s) over the learner's topics, as the paper does not give this aggregation.

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
