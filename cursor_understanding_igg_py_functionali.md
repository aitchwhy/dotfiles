# Understanding @igg.py Functionality
_Exported on 5/21/2025 at 02:15:24 EDT from Cursor (0.50.5)_

---

**User**

explain @igg.py and how it works

---

**Cursor**

`workflows/src/guideline_intelligence/models/igg.py` defines a small, strongly-typed domain-model for representing a clinical guideline as a traversable graph that an LLM (or any other reasoning engine) can follow while auditing how a nurse would review a patient’s record.  Everything is expressed with Pydantic models, so you automatically get validation, (de-)serialization and JSON-schema generation “for free”.

Key pieces, in the order they appear:

1. OutcomeSentiment (StrEnum)  
   • Encodes whether reaching a particular outcome is good, bad or neutral for the patient (`POSITIVE`, `NEGATIVE`, `NEUTRAL`).  
   • StrEnum makes the value itself equal the name string (useful when emitting JSON).

2. GuidelineOutcome (BaseModel)  
   • A leaf-node payload that says “if you stop here, this is the conclusion”.  
   • Fields  
     – description Natural-language explanation of the outcome.  
     – tagline Short snake-case identifier (≤ 3 words) for UI chips or anchors.  
     – sentiment One of the `OutcomeSentiment` values, used by the front-end to color-code the result (green/red/grey, etc.).

3. GuidelineCriterion (BaseModel)  
   • The atomic decision checkpoints inside a guideline (e.g. “patient is ≥ 18 years old”).  
   • Fields  
     – id Human-readable, unique, lower-snake-case or section number (“10.1”, “contrast_ct_required_iii”, …).  
     – description What is being checked, paraphrased or copied verbatim.  
     – conditions List of individual, clearly separable clinical conditions that must all be evaluated.  
     – citation `GuidelineCitation` (defined elsewhere) pin-points exactly where in the source document this criterion comes from.

4. NodeType (StrEnum) and BaseNode  
   • Small discriminated-union helper: each node knows if it’s the graph root, another criterion, or a leaf outcome.

5. OutcomeNode(CriterionNode)  
   • Two concrete node types inherit from `BaseNode`.  
   • `OutcomeNode` carries a `GuidelineOutcome`.  
   • `CriterionNode` carries a back-reference (`guideline_criterion_id`) to one of the criterion objects defined earlier.

6. Edge (BaseModel)  
   • Directed connection in the graph (`origin → destination`).  
   • origin: always a `CriterionNode` (you decide something and then move on).  
   • destination: either the next `CriterionNode` or an `OutcomeNode` (terminates the path).  
   • logic: free-text statement the LLM will evaluate to decide whether the edge should be followed (“ALL conditions met”, “IF age ≥ 65”, etc.).  
   • description: very short label for UI (“Patient is male”).

7. IGG (Intelligent Guideline Graph)  
   • The top-level object that groups everything.  
   • `guideline_title` Human title (“NICE NG123 Headache guideline”).  
   • `criteria` Flat list of all `GuidelineCriterion` objects (source-of-truth for each decision point).  
   • `nodes` Flat list of all graph nodes (criteria and outcomes).  
   • `edges` Flat list of all directed edges that join the nodes together.

   ➜ Design note in the docstring: a node does not store its outgoing edges directly. That keeps the node schema simple and avoids forcing the LLM to “know every child up-front”. Instead, you compute or fetch the relevant edges dynamically during traversal.

How it is typically used end-to-end
------------------------------------

1. A guideline author (or another model) populates the `criteria`, `nodes`, and `edges` lists to encode the paper/pdf guideline as a graph.  
2. At runtime an inference agent (e.g. OpenAI function-calling or your bespoke engine) starts at the root node, presents the criterion to the LLM along with the patient’s EMR facts, and asks “Does the logic on edge X apply?”.  
3. Based on the answer it chooses the correct `destination` node, continuing until it lands on an `OutcomeNode`.  
4. The outcome (with sentiment) is shown to the nurse, and every edge decision forms an auditable trail.

Why the structure matters
-------------------------

• **Pydantic validation** guarantees every IGG you load is well-formed.  
• **Separation of concerns** lets multiple teams work on content (criteria), logic (edges) and UI (outcome tags) independently.  
• **Auditability**: every edge stores the literal logic string plus the originating citation, which is crucial for regulatory/clinical review.  
• **LLM friendliness**: plain-text fields and StrEnums serialize naturally to JSON for function calls or prompts.

In short, `igg.py` is the typed contract for building, storing and traversing an intelligent, transparent representation of complex clinical guidelines.

