/**
 * Contact-form logic, with no DOM and no network in sight.
 *
 * Everything here is a pure function, so the whole submission path — validation
 * rules, HTML escaping, and the exact Firestore commit payload — is verifiable
 * without a browser. `main.js` supplies the DOM; `test/contact.test.mjs`
 * supplies fixtures. Sources of nondeterminism (document IDs) are parameters
 * rather than ambient calls, which is what makes the payload assertable.
 */

export const CONTACT_EMAIL = 'divaibhavyanshu@gmail.com';
export const PROJECT_ID = 'port-fol-io';

/**
 * Not a secret: it identifies the Firebase project rather than authorising
 * anything, it was already public inside the old Flutter bundle, and every
 * write is still governed by the Firestore security rules.
 */
export const API_KEY = 'AIzaSyDpbsuZ6GMrAOX7dZNqwlgftpsOySXSg8g';

export const COMMIT_URL =
  `https://firestore.googleapis.com/v1/projects/${PROJECT_ID}` +
  `/databases/(default)/documents:commit?key=${API_KEY}`;

const DOC_ROOT = `projects/${PROJECT_ID}/databases/(default)/documents/`;

// ─── Validation ──────────────────────────────────────────────────────────────

/** Deliberately liberal: the delivery attempt is the real check. */
const EMAIL_PATTERN = /^[^@]+@[^@]+\.[^@]+/;

/**
 * Field order matters — it decides which field receives focus when several are
 * invalid at once. Messages are carried over verbatim from the Dart validators.
 */
export const FIELD_RULES = [
  ['name', (v) => (v ? null : 'Please enter your name')],
  ['email', (v) => {
    if (!v) return 'Please enter your email';
    return EMAIL_PATTERN.test(v) ? null : 'Please enter a valid email';
  }],
  ['subject', (v) => (v ? null : 'Please enter the subject')],
  ['message', (v) => (v ? null : 'Please enter your message')],
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

/** Mirrors `_esc` in the Dart original — quotes are left alone there too. */
export function escapeHtml(value) {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;');
}

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
const strArray = (list) => ({ arrayValue: { values: list.map(str) } });
const map = (fields) => ({ mapValue: { fields } });

/**
 * Builds the single atomic commit that replaces the Dart version's two
 * sequential `.add()` calls: the submission log and the queued notification
 * email now either both land or neither does.
 *
 * `currentDocument: {exists: false}` makes each write a create rather than an
 * overwrite, so a colliding ID fails loudly instead of clobbering a record.
 *
 * @param {{name: string, email: string, subject: string, message: string}} values
 * @param {{formId: string, mailId: string}} ids
 */
export function buildCommit(values, ids) {
  const name = values.name.trim();
  const email = values.email.trim();
  const subject = values.subject.trim();
  const message = values.message.trim();

  const html =
    `<p><strong>From:</strong> ${escapeHtml(name)} ` +
    `(<a href="mailto:${escapeHtml(email)}">${escapeHtml(email)}</a>)</p>` +
    `<p><strong>Subject:</strong> ${escapeHtml(subject)}</p>` +
    '<hr>' +
    `<p>${escapeHtml(message).replace(/\n/g, '<br>')}</p>`;

  return {
    writes: [
      {
        update: {
          name: `${DOC_ROOT}form/${ids.formId}`,
          fields: {
            name: str(name),
            email: str(email),
            subject: str(subject),
            description: str(message),
          },
        },
        // The REST equivalent of FieldValue.serverTimestamp(): the field is
        // set by the server, so it must not also appear in `fields` above.
        updateTransforms: [
          { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
        ],
        currentDocument: { exists: false },
      },
      {
        update: {
          name: `${DOC_ROOT}mail/${ids.mailId}`,
          fields: {
            to: strArray([CONTACT_EMAIL]),
            replyTo: str(email),
            // Consumed by the "Trigger Email from Firestore" extension, which
            // dictates this exact shape.
            message: map({
              subject: str(`Portfolio enquiry: ${subject}`),
              text: str(
                `From: ${name} <${email}>\n` +
                `Subject: ${subject}\n\n` +
                message
              ),
              html: str(html),
            }),
          },
        },
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
  const documentIds = ids ?? { formId: autoId(), mailId: autoId() };

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
