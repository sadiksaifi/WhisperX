# Execution Protocol

This document defines how to execute the step files in `specs/` in a strict, linear order so each step is verified before moving on.

## Principle
- Implement **exactly one step at a time**.
- **Stop** after finishing a step to let the human verify.
- **Do not** start the next step until the previous step is explicitly approved.

## Step-by-step workflow
For each step file (`specs/step-1.md`, `specs/step-2.md`, ...), follow this loop:

1. **Read the current step file**
   - Review the Goal, Deliverables, TODOs, and Design Notes.
   - Confirm any open assumptions with the human before coding.

2. **Implement only that step**
   - Touch only the files necessary for the step’s TODOs.
   - Keep changes tightly scoped to that step.

3. **Document code as required**
   - Follow the “Agent documentation requirements” at the end of the step file.

4. **Self-check (lightweight)**
   - Ensure the Deliverables for the step are satisfied.
   - Verify no extra scope slipped in.
   - Build the app to confirm the step compiles; if it fails, fix the build errors before marking the step complete.

5. **Mark the step completed**
   - Report completion in the response (e.g., “Step 1 complete”).
   - Provide a brief change summary and the human verification plan from the step file.

6. **Stop and wait**
   - Do not implement the next step yet.
   - Ask the human to verify and approve before continuing.

## Order of execution
- Step 1: `specs/step-1.md`
- Step 2: `specs/step-2.md`
- Step 3: `specs/step-3.md`
- Step 4: `specs/step-4.md`
- Step 5: `specs/step-5.md`

## Completion criteria
A step is considered complete when:
- All TODOs in that step are implemented.
- Agent documentation requirements are satisfied.
- Human verification is completed and approved.
