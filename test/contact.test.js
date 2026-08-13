/**
 * Unit tests for the contact-form logic.
 *
 * Runs on Node's built-in test runner — no framework, no dependencies:
 *
 *     npm test
 *
 * The point of these is the payload: the `mail` document shape is dictated by
 * the Firebase "Trigger Email from Firestore" extension, and getting a field
 * name wrong there fails silently at send time rather than loudly at build
 * time. Pinning it here is the only cheap way to catch that.
 */

import test from 'node:test';
import assert from 'node:assert/strict';

import {
  API_KEY,
  COMMIT_URL,
  CONTACT_EMAIL,
  autoId,
  buildCommit,
  escapeHtml,
  send,
  validate,
} from '../site/contact.js';

const VALID = {
  name: 'Ada Lovelace',
  email: 'ada@example.com',
  subject: 'Analytical Engine',
  message: 'Hello there.',
};

const IDS = { formId: 'formDoc0000000000001', mailId: 'mailDoc0000000000001' };

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

// ─── Escaping ────────────────────────────────────────────────────────────────

test('escapes the three characters the Dart original escaped', () => {
  assert.equal(escapeHtml('<b>&</b>'), '&lt;b&gt;&amp;&lt;/b&gt;');
});

test('escapes ampersands before angle brackets, so entities survive one pass', () => {
  // Wrong order yields '&lt;' -> '&amp;lt;' only if & is escaped second.
  assert.equal(escapeHtml('<'), '&lt;');
  assert.equal(escapeHtml('&lt;'), '&amp;lt;');
});

test('leaves quotes alone, matching the Dart behaviour', () => {
  assert.equal(escapeHtml('say "hi"'), 'say "hi"');
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

test('writes the log and the queued email in one atomic commit', () => {
  const { writes } = buildCommit(VALID, IDS);
  assert.equal(writes.length, 2);
});

test('addresses both documents to the right project and collection', () => {
  const [log, mail] = buildCommit(VALID, IDS).writes;
  const root = 'projects/port-fol-io/databases/(default)/documents';

  assert.equal(log.update.name, `${root}/form/${IDS.formId}`);
  assert.equal(mail.update.name, `${root}/mail/${IDS.mailId}`);
});

test('creates rather than overwrites, so an ID collision fails loudly', () => {
  for (const write of buildCommit(VALID, IDS).writes) {
    assert.deepEqual(write.currentDocument, { exists: false });
  }
});

test('defers createdAt to the server instead of trusting the client clock', () => {
  const [log] = buildCommit(VALID, IDS).writes;

  assert.deepEqual(log.updateTransforms, [
    { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' },
  ]);
  // A server-set field must not also be present in `fields`.
  assert.equal(log.update.fields.createdAt, undefined);
});

test('stores the message verbatim in the log, under the Dart field name', () => {
  const values = { ...VALID, message: 'raw <angle> & amp' };
  const [log] = buildCommit(values, IDS).writes;

  assert.deepEqual(log.update.fields.description, { stringValue: 'raw <angle> & amp' });
});

test('trims every field before persisting it', () => {
  const padded = {
    name: '  Ada  ',
    email: '  ada@example.com  ',
    subject: '  Subject  ',
    message: '  Body  ',
  };
  const [log] = buildCommit(padded, IDS).writes;

  assert.deepEqual(log.update.fields.name, { stringValue: 'Ada' });
  assert.deepEqual(log.update.fields.email, { stringValue: 'ada@example.com' });
  assert.deepEqual(log.update.fields.subject, { stringValue: 'Subject' });
  assert.deepEqual(log.update.fields.description, { stringValue: 'Body' });
});

test('builds the exact envelope the Trigger Email extension expects', () => {
  const [, mail] = buildCommit(VALID, IDS).writes;
  const fields = mail.update.fields;

  assert.deepEqual(fields.to, {
    arrayValue: { values: [{ stringValue: CONTACT_EMAIL }] },
  });
  assert.deepEqual(fields.replyTo, { stringValue: VALID.email });
  assert.deepEqual(Object.keys(fields.message.mapValue.fields).sort(), [
    'html',
    'subject',
    'text',
  ]);
});

test('prefixes the email subject so replies are filterable', () => {
  const [, mail] = buildCommit(VALID, IDS).writes;

  assert.equal(
    mail.update.fields.message.mapValue.fields.subject.stringValue,
    'Portfolio enquiry: Analytical Engine'
  );
});

test('sets replyTo to the sender so replying reaches them, not the site', () => {
  const [, mail] = buildCommit({ ...VALID, email: 'someone@else.test' }, IDS).writes;
  assert.equal(mail.update.fields.replyTo.stringValue, 'someone@else.test');
});

test('escapes sender-controlled text in the HTML body', () => {
  const hostile = {
    ...VALID,
    name: '<script>alert(1)</script>',
    subject: 'a & b',
    message: 'x < y',
  };
  const html = buildCommit(hostile, IDS)
    .writes[1].update.fields.message.mapValue.fields.html.stringValue;

  assert.ok(!html.includes('<script>'), 'raw script tag reached the email body');
  assert.ok(html.includes('&lt;script&gt;alert(1)&lt;/script&gt;'));
  assert.ok(html.includes('a &amp; b'));
  assert.ok(html.includes('x &lt; y'));
});

test('keeps the plain-text part unescaped, as the Dart version did', () => {
  const text = buildCommit({ ...VALID, name: 'A <b> C' }, IDS)
    .writes[1].update.fields.message.mapValue.fields.text.stringValue;

  assert.ok(text.includes('From: A <b> C <ada@example.com>'));
});

test('turns newlines into line breaks in HTML but leaves them in text', () => {
  const values = { ...VALID, message: 'one\ntwo' };
  const { fields } = buildCommit(values, IDS).writes[1].update.fields.message.mapValue;

  assert.ok(fields.html.stringValue.includes('one<br>two'));
  assert.ok(fields.text.stringValue.includes('one\ntwo'));
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

test('generates its own IDs when none are supplied', async () => {
  const seen = [];
  await send(VALID, {
    fetchImpl: async (_url, options) => {
      seen.push(...JSON.parse(options.body).writes.map((w) => w.update.name));
      return { ok: true };
    },
  });

  assert.equal(seen.length, 2);
  assert.notEqual(seen[0], seen[1]);
  for (const name of seen) assert.match(name, /\/[A-Za-z0-9]{20}$/);
});

// ─── Configuration ───────────────────────────────────────────────────────────

test('commit URL carries the project and key Firestore requires', () => {
  const url = new URL(COMMIT_URL);
  assert.equal(url.origin, 'https://firestore.googleapis.com');
  assert.ok(url.pathname.includes('/projects/port-fol-io/'));
  assert.ok(url.pathname.endsWith(':commit'));
  assert.equal(url.searchParams.get('key'), API_KEY);
});
