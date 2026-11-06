/**
 * Contact-form logic, with no DOM and no network in sight.
 *
 * Everything here is a pure function, so the whole submission path — validation
 * rules, HTML escaping, and the exact Firestore commit payload — is verifiable
 * without a browser. `main.js` supplies the DOM; `test/contact.test.mjs`
 * supplies fixtures. Sources of nondeterminism (document IDs) are parameters
 * rather than ambient calls, which is what makes the payload assertable.
 */

/**
 * Messages go to the Firebase project behind the owner's Arclight app, which
 * shows them and notifies the owner's phone. Its security rules
 * (firestore.rules in the patentanalystcompany repo) let anyone create one
 * message with exactly the fields below, and nobody but the owner read it.
 * No API key is needed: an unauthenticated write is judged by those rules.
 */
export const PROJECT_ID = 'chrome-1st-extension';
export const COLLECTION = 'portfolio_messages';

export const COMMIT_URL =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
  `/databases/(default)/documents:commit`;

const DOC_ROOT = `projects/${PROJECT_ID}/databases/(default)/documents/`;

// ─── Validation ──────────────────────────────────────────────────────────────

/** Deliberately liberal, and the same pattern the security rules apply. */
const EMAIL_PATTERN = /^[^@]+@[^@]+\.[^@]+$/;

/** The longest each field may be; the security rules refuse anything longer. */
export const MAX_LENGTH = { name: 200, email: 320, subject: 300, message: 5000 };

const tooLong = (field, v) =>
  v.length > MAX_LENGTH[field]
    ? `Please keep this under ${MAX_LENGTH[field].toLocaleString('en')} characters`
    : null;

/**
 * Field order matters — it decides which field receives focus when several are
 * invalid at once. Messages are carried over verbatim from the Dart validators.
 */
export const FIELD_RULES = [
  ['name', (v) => (v ? tooLong('name', v) : 'Please enter your name')],
  ['email', (v) => {
    if (!v) return 'Please enter your email';
    return EMAIL_PATTERN.test(v) ? tooLong('email', v) : 'Please enter a valid email';
  }],
  ['subject', (v) => (v ? tooLong('subject', v) : 'Please enter the subject')],
  ['message', (v) => (v ? tooLong('message', v) : 'Please enter your message')],
];

/**
 * @param {Record<string, string>} values raw field values; whitespace-only
 *   input counts as empty, matching the Dart `.trim()` before validation.
 * @returns {{valid: boolean, errors: Record<string, string>, firstInvalid: string|null}}
 */
export function validate(values) {
  const errors = {};
  let firstInvalid = null;

  for (const [field, rule] of FIELD_RULES) {
    const message = rule((values[field] ?? '').trim());
    if (message) {
      errors[field] = message;
      firstInvalid ??= field;
    }
  }

  return { valid: firstInvalid === null, errors, firstInvalid };
}

// ─── Payload construction ────────────────────────────────────────────────────

const ID_ALPHABET =
  'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

/**
 * A Firestore-shaped auto-ID: 20 characters of [A-Za-z0-9].
 *
 * `randomBytes` is injectable so tests can pin the output. The modulo is
 * slightly biased across 62 symbols, which is irrelevant here — these IDs only
 * need to not collide, they carry no security weight.
 */
export function autoId(randomBytes = (n) => crypto.getRandomValues(new Uint8Array(n))) {
  const bytes = randomBytes(20);
  let id = '';
  for (let i = 0; i < 20; i++) id += ID_ALPHABET[bytes[i] % ID_ALPHABET.length];
  return id;
}

const str = (stringValue) => ({ stringValue });

/**
 * Builds the commit that saves one message: exactly the fields the security
 * rules accept, with `createdAt` set by the server.
 *
 * `currentDocument: {exists: false}` makes the write a create rather than an
 * overwrite, so a colliding ID fails loudly instead of clobbering a message
 * (and the rules only allow creating one anyway).
 *
 * @param {{name: string, email: string, subject: string, message: string}} values
 * @param {{messageId: string}} ids
 */
export function buildCommit(values, ids) {
  return {
    writes: [
      {
        update: {
          name: `${DOC_ROOT}${COLLECTION}/${ids.messageId}`,
          fields: {
            name: str(values.name.trim()),
            email: str(values.email.trim()),
            subject: str(values.subject.trim()),
            message: str(values.message.trim()),
          },
        },
        // The REST equivalent of FieldValue.serverTimestamp(): the field is
        // set by the server, so it must not also appear in `fields` above.
        updateTransforms: [
          { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
        ],
        currentDocument: { exists: false },
      },
    ],
  };
}

// ─── Delivery ────────────────────────────────────────────────────────────────

/**
 * Posts the commit and normalises Firestore's error envelope into an Error.
 * `fetchImpl` is injectable so tests never touch the network.
 */
export async function send(values, { fetchImpl = fetch, ids } = {}) {
  const documentIds = ids ?? { messageId: autoId() };

  const response = await fetchImpl(COMMIT_URL, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(buildCommit(values, documentIds)),
  });

  if (response.ok) return;

  let detail = `HTTP ${response.status}`;
  try {
    const payload = await response.json();
    detail = payload?.error?.message || detail;
  } catch {
    // Non-JSON error body; the status line is all we have.
  }
  throw new Error(detail);
}
