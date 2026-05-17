const {onRequest, HttpsError} = require('firebase-functions/v2/https');
const logger = require('firebase-functions/logger');
const admin = require('firebase-admin');
const crypto = require('node:crypto');

admin.initializeApp();

const db = admin.firestore();
const FEEDBACK_COLLECTION = 'feedback_submissions';
const LIMIT_COLLECTION = 'feedback_ingest_limits';
const WINDOW_MS = 10 * 60 * 1000;

function firstForwardedIp(req) {
  const forwarded = req.get('x-forwarded-for');
  if (!forwarded) {
    return req.ip || 'unknown';
  }
  return forwarded.split(',')[0].trim();
}

function sha256(input) {
  return crypto.createHash('sha256').update(input).digest('hex');
}

function sanitizePayload(body, userId) {
  return {
    message: String(body.message || '').trim(),
    category: String(body.category || '').trim(),
    source: String(body.source || '').trim(),
    email: body.email == null ? null : String(body.email).trim(),
    device_fingerprint: String(body.device_fingerprint || '').trim(),
    platform: String(body.platform || '').trim(),
    app_version: String(body.app_version || '').trim(),
    build_number: String(body.build_number || '').trim(),
    locale: String(body.locale || '').trim(),
    user_id: userId,
    created_at_client: String(body.created_at_client || '').trim(),
    status: 'new',
    // Optional honeypot field; legitimate clients should not set this.
    hp: body.hp == null ? '' : String(body.hp),
  };
}

function validatePayload(payload) {
  const categoryOk = ['bug_report', 'feature_request', 'ux_feedback', 'other'].includes(payload.category);
  const sourceOk = ['settings', 'drawer'].includes(payload.source);
  const platformOk = ['android', 'ios', 'web'].includes(payload.platform);

  return (
    payload.message.length > 0 &&
    payload.message.length <= 2000 &&
    categoryOk &&
    sourceOk &&
    platformOk &&
    payload.device_fingerprint.length >= 8 &&
    payload.device_fingerprint.length <= 64 &&
    payload.app_version.length > 0 &&
    payload.build_number.length > 0 &&
    payload.locale.length > 0
  );
}

function scoreBotRisk(payload) {
  let score = 0;
  if (payload.hp.length > 0) {
    score += 100;
  }
  if (payload.message.length < 12) {
    score += 20;
  }
  if (/https?:\/\//i.test(payload.message)) {
    score += 30;
  }
  return score;
}

exports.submitFeedbackIngest = onRequest(
  {
    region: 'us-central1',
    cors: true,
    enforceAppCheck: true,
    invoker: 'public',
  },
  async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).json({error: 'method_not_allowed'});
      return;
    }

    const authHeader = req.get('authorization') || '';
    const idToken = authHeader.startsWith('Bearer ') ? authHeader.slice(7) : '';
    if (!idToken) {
      res.status(401).json({error: 'missing_bearer_token'});
      return;
    }

    let decoded;
    try {
      decoded = await admin.auth().verifyIdToken(idToken);
    } catch (error) {
      logger.warn('verifyIdToken failed', error);
      res.status(401).json({error: 'invalid_token'});
      return;
    }

    const payload = sanitizePayload(req.body || {}, decoded.uid);
    if (!validatePayload(payload)) {
      res.status(400).json({error: 'invalid_payload'});
      return;
    }

    const riskScore = scoreBotRisk(payload);
    if (riskScore >= 100) {
      res.status(403).json({error: 'bot_detected'});
      return;
    }

    const ip = firstForwardedIp(req);
    const ipHash = sha256(ip);
    const rateKey = sha256(`${decoded.uid}:${ipHash}`);
    const nowMs = Date.now();
    const windowId = Math.floor(nowMs / WINDOW_MS);
    const feedbackId = `${decoded.uid}_${payload.device_fingerprint}_${windowId}`;

    const limitRef = db.collection(LIMIT_COLLECTION).doc(rateKey);
    const feedbackRef = db.collection(FEEDBACK_COLLECTION).doc(feedbackId);

    try {
      await db.runTransaction(async (tx) => {
        const limitSnap = await tx.get(limitRef);
        const lastAt = limitSnap.exists ? limitSnap.get('last_submission_ms') : null;

        if (typeof lastAt === 'number' && nowMs - lastAt < WINDOW_MS) {
          throw new HttpsError('resource-exhausted', 'rate_limited');
        }

        tx.set(
          feedbackRef,
          {
            ...payload,
            created_at: admin.firestore.FieldValue.serverTimestamp(),
            app_check_enforced: true,
            bot_risk_score: riskScore,
            ip_hash: ipHash,
            ingest_source: 'cloud_function',
          },
          {merge: true},
        );

        tx.set(
          limitRef,
          {
            last_submission_ms: nowMs,
            updated_at: admin.firestore.FieldValue.serverTimestamp(),
          },
          {merge: true},
        );
      });
    } catch (error) {
      if (error instanceof HttpsError && error.code === 'resource-exhausted') {
        res.status(429).json({error: 'rate_limited'});
        return;
      }
      logger.error('submitFeedbackIngest failed', error);
      res.status(500).json({error: 'internal_error'});
      return;
    }

    res.status(200).json({status: 'ok', id: feedbackId, risk_score: riskScore});
  },
);
