```markdown
## Context
Receipt OCR and batch photo capture require datasets, labeling and evaluation processes which are not defined.

## Goal
Define dataset schema, labeling workflow, evaluation metrics and minimal infrastructure for model training and reproducible evaluation.

## Expected behavior
- A documented dataset layout, labeling guidelines, an evaluation script and target metrics for OCR and object detection tasks.

## Acceptance criteria (Definition of Done)
- [ ] Dataset schema & storage location documented.
- [ ] Labeling guidelines and a small seed dataset (100–500 items) included.
- [ ] Evaluation scripts for OCR and detection with baseline metrics.
- [ ] CI job to run evaluation on new model artifacts.

## Out of scope
- Full production model training at scale.

## Implementation notes
- Use standard formats (COCO, VOC, JSONL for OCR); track versions with small dataset snapshot in repo (or storage reference).

## Test plan
- Run evaluation script against seed dataset and record baseline metrics.

## Dependencies
- Complete before starting issues 430, 440, 450, 460, 185 (all ML-dependent features)

```
