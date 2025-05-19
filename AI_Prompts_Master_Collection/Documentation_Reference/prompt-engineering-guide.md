# Prompt Engineering Guide

## Introduction to Prompt Engineering

Prompt engineering is the practice of designing effective inputs for large language models (LLMs) to produce desired outputs. It's an evolving discipline that combines elements of communication, programming, and psychology to reliably guide AI behavior.

## Core Principles for Beginners

### 1. Be Clear and Specific

- **State exactly what you want**: Define the task, expected format, and scope clearly
- **Avoid ambiguity**: Eliminate vague terms that could be interpreted multiple ways
- **Set boundaries**: Specify what the model should NOT do as well as what it should do

### 2. Provide Context

- **Establish background information**: Give relevant context the model needs
- **Define audience**: Specify who the response is for (experts, beginners, etc.)
- **State purpose**: Explain why you need this information and how it will be used

### 3. Use Examples (Few-Shot Learning)

- **Demonstrate desired outputs**: Show 1-3 examples of ideal responses
- **Illustrate edge cases**: Include examples of challenging scenarios
- **Maintain consistency**: Keep a similar structure across all examples

## Maximizing Accuracy

### 1. Knowledge Scaffolding

Break complex tasks into smaller steps:

```
1. First, identify the key facts in this medical case
2. Then, compare these facts to clinical guidelines
3. Finally, generate a recommendation based on this analysis
```

### 2. Chain-of-Thought Prompting

Ask the model to "think step by step" or "reason through this carefully":

```
Analyze this lab result by:
1. Identifying abnormal values
2. Explaining what each abnormality might indicate
3. Suggesting possible clinical implications
Think through each step carefully.
```

### 3. Self-Consistency Checks

Instruct the model to verify its own work:

```
After providing your analysis, review your reasoning for logical errors or unsupported claims.
```

## Improving Consistency

### 1. Use Clear Structural Templates

```
[TASK]: Summarize the following clinical note
[FORMAT]: 
- Chief complaint:
- Key findings:
- Assessment:
- Plan:
[REQUIREMENTS]: Keep it under 100 words
[INPUT]: {text}
```

### 2. Control Parameters

- **Temperature**: Lower values (0.1-0.3) for factual, consistent responses
- **Response length**: Specify word/character count for consistent sizing
- **Sampling techniques**: Nucleus or top-k sampling for balanced control

### 3. Provide Evaluation Criteria

```
Your response will be evaluated on:
1. Factual accuracy (all claims must be supported by the document)
2. Completeness (all key information must be included)
3. Clarity (information must be organized logically)
```

## Enhancing Resiliency

### 1. Anticipate Variations

Prepare your prompt to handle different inputs:

```
If the input contains lab values, format them in a table.
If the input contains symptoms, list them in bullet points.
If the input is incomplete, identify what information is missing.
```

### 2. Error Handling

Instruct the model how to respond to ambiguity or insufficient information:

```
If you're uncertain about any aspect of your response, explicitly state your uncertainty.
If critical information is missing, indicate what additional data would be needed.
```

### 3. Guardrails and Constraints

Set clear boundaries for responses:

```
Only include information explicitly stated in the document. Do not introduce external information or assumptions.
```

## Getting Structured Responses

### 1. Define Output Format Explicitly

#### JSON Format

```
Return your analysis as a valid JSON object with the following structure:
{
  "diagnosis": string,
  "confidence": number (1-5),
  "supporting_evidence": string[],
  "alternative_explanations": string[]
}
```

#### XML Format

```
Format your response as XML using the following tags:
<assessment>
  <findings>List key findings here</findings>
  <diagnosis>Primary diagnosis here</diagnosis>
  <plan>Treatment plan here</plan>
</assessment>
```

#### Tabular Format

```
Present the medication information in a table with these columns:
- Medication name
- Dosage
- Frequency
- Purpose
- Side effects
```

### 2. Validation Instructions

```
Ensure your JSON response:
1. Contains all required fields
2. Uses the correct data types for each field
3. Has no extra fields not specified in the schema
```

### 3. Consistency Enforcement

```
Follow these rules consistently:
- Use present tense for all descriptions
- Express all measurements in metric units
- Format all dates as YYYY-MM-DD
```

## Maintaining Formal Structures

### 1. Schema Definitions

Define your structures using familiar formats:

```
Follow this JSON schema:
{
  "type": "object",
  "required": ["patient_id", "vital_signs", "assessment"],
  "properties": {
    "patient_id": { "type": "string" },
    "vital_signs": {
      "type": "object",
      "properties": {
        "temperature": { "type": "number" },
        "heart_rate": { "type": "number" },
        "blood_pressure": { "type": "string" }
      }
    },
    "assessment": { "type": "string" }
  }
}
```

### 2. Enumeration for Fixed Values

```
Use only these values for the 'severity' field:
- "mild"
- "moderate" 
- "severe"
- "critical"
```

### 3. Versioning

```
This prompt uses response schema version 2.1.
Changes from v2.0:
- Added 'confidence_score' field
- 'complications' field is now optional
```

## Advanced Techniques

### 1. Role-Based Prompting

Assign a specific role to the model:

```
You are an experienced medical transcriptionist with specialty training in cardiology. Your task is to...
```

### 2. Multi-Step Workflows

Break complex tasks into stages:

```
This is a 3-step process:
STEP 1: Extract all medical terms from the text
STEP 2: Categorize each term as diagnosis, medication, or procedure
STEP 3: Generate a structured summary using these categorized terms
```

### 3. Reflection and Refinement

Have the model improve its own answers:

```
After generating your initial response, critique it for accuracy and completeness. Then provide an improved version addressing any deficiencies.
```

## Common Pitfalls to Avoid

- **Prompts that are too vague**: "Summarize this" vs. "Provide a 3-paragraph summary highlighting key diagnoses"
- **Contradictory instructions**: Asking for both brevity and exhaustive detail
- **Failing to specify constraints**: Not setting clear parameters on response length, format, or scope
- **Overly complex structures**: Creating schemas that are too detailed or nested
- **Ignoring edge cases**: Not considering how the prompt handles unusual inputs

## Testing and Iterating

The most effective prompts are developed through systematic testing:

1. Start with a basic version of your prompt
2. Test with diverse inputs
3. Identify failure modes and inconsistencies
4. Refine the prompt to address these issues
5. Document what works and why