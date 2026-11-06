/**
 * Unit tests for the contact-form logic.
 *
 * Runs on Node's built-in test runner — no framework, no dependencies:
 *
 *     npm test
 *
 * The point of these is the payload: the security rules in front of the
 * Firebase project accept exactly these fields, lengths and a server-set
 * createdAt, and refuse anything else with a bare "permission denied" at send
 * time. Pinning the shape here catches that at build time instead.
 */

import test from 'node:test';
import assert from 'node:assert/strict';

import {
  COLLECTION,
  COMMIT_URL,
  MAX_LENGTH,
  PROJECT_ID,
  autoId,
  buildCommit,
  send,
  validate,
} from '../site/contact.js';

const VALID = {
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  subject: 'Analytical Engine',
  message: 'Hello there.',
};

const IDS = { messageId: 'messageDoc0000000001' };

// ─── Validation ──────────────────────────────────────────────────────────────

test('accepts a fully populated form', () => {
  const result = validate(VALID);
  assert.equal(result.valid, true);
  assert.deepEqual(result.errors, {});
  assert.equal(result.firstInvalid, null);
});

test('reports every empty field at once, not just the first', () => {
  const result = validate({ name: '', email: '', subject: '', message: '' });

  assert.equal(result.valid, false);
  assert.deepEqual(result.errors, {
    name: 'Please enter your name',
    email: 'Please enter your email',
    subject: 'Please enter the subject',
    message: 'Please enter your message',
  });
});

test('focuses the first invalid field in document order', () => {
  assert.equal(validate({ ...VALID, name: '', subject: '' }).firstInvalid, 'name');
  assert.equal(validate({ ...VALID, subject: '' }).firstInvalid, 'subject');
});

test('treats whitespace-only input as empty', () => {
  const result = validate({ ...VALID, message: '   \n\t  ' });
  assert.equal(result.valid, false);
  assert.equal(result.errors.message, 'Please enter your message');
});

test('treats a missing key the same as an empty string', () => {
  const result = validate({ name: 'Ada' });
  assert.equal(result.valid, false);
  assert.equal(result.errors.email, 'Please enter your email');
});

test('distinguishes a malformed address from a missing one', () => {
  assert.equal(
    validate({ ...VALID, email: 'ada@example' }).errors.email,
    'Please enter a valid email'
  );
  assert.equal(
    validate({ ...VALID, email: '' }).errors.email,
    'Please enter your email'
  );
});

test('accepts addresses that trip up naive patterns', () => {
  for (const email of [
    'ada+tag@example.co.uk',
    'a@b.io',
    'first.last@sub.domain.example',
  ]) {
    assert.equal(validate({ ...VALID, email }).valid, true, email);
  }
});

test('refuses what the security rules would refuse, with a message', () => {
  const long = (n) => 'x'.repeat(n);
  assert.equal(validate({ ...VALID, message: long(MAX_LENGTH.message) }).valid, true);
  assert.equal(
    validate({ ...VALID, message: long(MAX_LENGTH.message + 1) }).errors.message,
    'Please keep this under 5,000 characters'
  );
  assert.equal(validate({ ...VALID, name: long(201) }).firstInvalid, 'name');
  assert.equal(validate({ ...VALID, subject: long(301) }).firstInvalid, 'subject');
  assert.equal(validate({ ...VALID, email: `${long(320)}@example.com` }).firstInvalid, 'email');
  assert.equal(validate({ ...VALID, email: 'a@b.co@x' }).errors.email, 'Please enter a valid email');
});

// ─── Document IDs ────────────────────────────────────────────────────────────

test('generates Firestore-shaped auto-IDs', () => {
  const id = autoId(() => new Uint8Array(20).fill(0));
  assert.equal(id.length, 20);
  assert.match(id, /^[A-Za-z0-9]{20}$/);
});

test('maps every byte value into the alphabet', () => {
  const id = autoId(() => Uint8Array.from({ length: 20 }, (_, i) => i * 13));
  assert.match(id, /^[A-Za-z0-9]{20}$/);
});

test('produces distinct IDs from real entropy', () => {
  const ids = new Set(Array.from({ length: 500 }, () => autoId()));
  assert.equal(ids.size, 500);
});

// ─── Commit payload ──────────────────────────────────────────────────────────

test('saves exactly one message, in the messages collection of the right project', () => {
  const { writes } = buildCommit(VALID, IDS);
  assert.equal(writes.length, 1);
  assert.equal(
    writes[0].update.name,
    `projects/chrome-1st-extension/databases/(default)/documents/portfolio_messages/${IDS.messageId}`
  );
});

test('sends only the fields the security rules accept', () => {
  const [write] = buildCommit(VALID, IDS).writes;
  assert.deepEqual(Object.keys(write.update.fields).sort(), ['email', 'message', 'name', 'subject']);
});

test('creates rather than overwrites, so an ID collision fails loudly', () => {
  assert.deepEqual(buildCommit(VALID, IDS).writes[0].currentDocument, { exists: false });
});

test('defers createdAt to the server instead of trusting the client clock', () => {
  const [write] = buildCommit(VALID, IDS).writes;

  assert.deepEqual(write.updateTransforms, [
    { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
  ]);
  // A server-set field must not also be present in `fields`.
  assert.equal(write.update.fields.createdAt, undefined);
});

test('stores the message verbatim', () => {
  const values = { ...VALID, message: 'raw <angle> & amp\nsecond line' };
  const [write] = buildCommit(values, IDS).writes;

  assert.deepEqual(write.update.fields.message, { stringValue: 'raw <angle> & amp\nsecond line' });
});

test('trims every field before persisting it', () => {
  const padded = {
    name: '  Ada  ',
    email: '  ada@example.com  ',
    subject: '  Subject  ',
    message: '  Body  ',
  };
  const [write] = buildCommit(padded, IDS).writes;

  assert.deepEqual(write.update.fields.name, { stringValue: 'Ada' });
  assert.deepEqual(write.update.fields.email, { stringValue: 'ada@example.com' });
  assert.deepEqual(write.update.fields.subject, { stringValue: 'Subject' });
  assert.deepEqual(write.update.fields.message, { stringValue: 'Body' });
});

test('serialises to JSON without losing anything', () => {
  const payload = buildCommit(VALID, IDS);
  assert.deepEqual(JSON.parse(JSON.stringify(payload)), payload);
});

// ─── Delivery ────────────────────────────────────────────────────────────────

test('posts JSON to the project commit endpoint', async () => {
  let captured;
  await send(VALID, {
    ids: IDS,
    fetchImpl: async (url, options) => {
      captured = { url, options };
      return { ok: true };
    },
  });

  assert.equal(captured.url, COMMIT_URL);
  assert.equal(captured.options.method, 'POST');
  assert.equal(captured.options.headers['Content-Type'], 'application/json');
  assert.deepEqual(JSON.parse(captured.options.body), buildCommit(VALID, IDS));
});

test('surfaces the Firestore error message rather than a bare status', async () => {
  await assert.rejects(
    send(VALID, {
      ids: IDS,
      fetchImpl: async () => ({
        ok: false,
        status: 403,
        json: async () => ({ error: { message: 'Missing or insufficient permissions.' } }),
      }),
    }),
    /Missing or insufficient permissions/
  );
});

test('falls back to the status line when the error body is not JSON', async () => {
  await assert.rejects(
    send(VALID, {
      ids: IDS,
      fetchImpl: async () => ({
        ok: false,
        status: 502,
        json: async () => { throw new SyntaxError('not JSON'); },
      }),
    }),
    /HTTP 502/
  );
});

test('generates its own ID when none is supplied', async () => {
  const seen = [];
  for (let i = 0; i < 2; i++) {
    await send(VALID, {
      fetchImpl: async (_url, options) => {
        seen.push(...JSON.parse(options.body).writes.map((w) => w.update.name));
        return { ok: true };
      },
    });
  }

  assert.equal(seen.length, 2);
  assert.notEqual(seen[0], seen[1]);
  for (const name of seen) assert.match(name, /\/[A-Za-z0-9]{20}$/);
});

// ─── Configuration ───────────────────────────────────────────────────────────

test('commit URL names the project, and needs no API key', () => {
  const url = new URL(COMMIT_URL);
  assert.equal(url.origin, 'https://firestore.googleapis.com');
  assert.ok(url.pathname.includes(`/projects/${PROJECT_ID}/`));
  assert.ok(url.pathname.endsWith(':commit'));
  assert.equal(url.search, '');
  assert.equal(COLLECTION, 'portfolio_messages');
});
