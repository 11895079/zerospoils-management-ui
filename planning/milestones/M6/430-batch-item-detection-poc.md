# 430 - Batch Item Detection POC (Computer Vision)

## Context
Product differentiator: detect multiple items from a single photo of a shelf or countertop, reducing manual entry friction.

## Goal
Deliver a proof-of-concept for batch item detection using computer vision object detection to identify multiple food items in one photo.

## Expected behavior
- User takes a single photo of multiple items (e.g., shelf, countertop, fridge contents)
- System detects item boundaries and suggests item names with confidence scores
- User reviews detected items and confirms/edits/skips each one
- Confirmed items are added to inventory

## Acceptance criteria (Definition of Done)
- [ ] POC object detection model integrated (YOLO, TensorFlow Lite, or cloud-based)
- [ ] Capture UI implemented (camera view with batch capture mode)
- [ ] Bounding box visualization shows detected items
- [ ] Review UI displays detected items with confidence scores (e.g., "Milk 85%", "Eggs 72%")
- [ ] User can accept, edit, or skip each detected item
- [ ] Confirmed items create inventory entries with suggested category/location
- [ ] Privacy consent flow implemented (image processing disclosure)
- [ ] Provide small labeled dataset (50 images) and evaluation script with precision/recall metrics
- [ ] Unit tests for detection pipeline
- [ ] Widget tests for camera capture and review UI
- [ ] Integration test: end-to-end batch capture workflow
- [ ] Telemetry: `batch_capture_started`, `batch_items_detected` (count, avg_confidence), `batch_item_confirmed`, `batch_item_skipped`
- [ ] Accessibility: Camera instructions announced, review list navigable with screen reader

## Out of scope
- Production-grade ML model (high accuracy, optimized inference)
- On-device model training or fine-tuning
- Real-time item detection (streaming camera)
- Integration with receipt OCR workflow (separate feature)
- Barcode/QR code scanning (separate feature)

## Implementation notes
- **Model options:**
  - Cloud-based: Google Cloud Vision API (object detection), AWS Rekognition
  - On-device: TensorFlow Lite with pre-trained object detection model (MobileNet SSD, YOLO)
- **Camera capture:** Use Flutter `camera` package; single tap to capture
- **Detection pipeline:** Image → model inference → bounding boxes + labels → parse results
- **Review UI:** List view with item image thumbnail, name, confidence, edit/skip buttons
- **Privacy:** Store captured image temporarily (delete after review); log consent in settings
- **Domain/data/ui layers:** `BatchDetectionService`, `BatchDetectionRepository`, `BatchCaptureScreen`, `BatchReviewScreen`

## Test plan

**Automated:**
- Unit test: Mock detection service returns 3 items; verify parsing and confidence scoring
- Widget test: Batch review screen renders 3 detected items with accept/skip buttons
- Integration test: Capture mock photo → detect items → confirm 2 items → verify inventory entries created

**Manual:**
1. Enable batch capture feature flag
2. Tap "Batch Add" button on inventory screen
3. Take photo of 3-5 items on countertop
4. Verify bounding boxes drawn on preview
5. Review detected items; edit one item name, skip one low-confidence item, accept others
6. Verify accepted items appear in inventory list
7. Check telemetry events logged (batch_capture_started, batch_items_detected, batch_item_confirmed)
8. Test with different lighting conditions (bright, dim) and item arrangements (clustered, spread out)

## Dependencies
- Issue 130: Feature flags framework (gate batch capture behind Pro tier flag)
- Issue 235: ML infrastructure (dataset schema, evaluation framework)
