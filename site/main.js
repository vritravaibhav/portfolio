/**
 * DOM wiring: copy buttons and the contact form, plus booting the backdrop
 * and the motion layer.
 *
 * All submission logic lives in contact.js, which is pure and unit-tested.
 * This file only moves values between the page and those functions.
 */

import { FIELD_RULES, validate, send } from './contact.js';
import { startBackdrop } from './backdrop.js';
import { initMotion } from './motion.js';

// Both are decoration: if either throws, the page is still a working document,
// so neither is allowed to take the form down with it.
try {
  const canvas = document.querySelector('.backdrop-gl');
  if (canvas) startBackdrop(canvas);
} catch (error) {
  console.warn('[backdrop] disabled:', error);
}

try {
  initMotion();
} catch (error) {
  console.warn('[motion] disabled:', error);
  // Whatever the reveal left hidden must come back.
  for (const target of document.querySelectorAll('[data-reveal]')) {
    target.classList.add('revealed');
  }
}

// ─── Toast (stands in for the Flutter SnackBar) ──────────────────────────────

const toastEl = document.querySelector('.toast');
let toastTimer;

function toast(message) {
  toastEl.replaceChildren();

  const icon = document.createElementNS('http://www.w3.org/2000/svg', 'svg');
  icon.setAttribute('class', 'ico');
  icon.setAttribute('aria-hidden', 'true');
  const use = document.createElementNS('http://www.w3.org/2000/svg', 'use');
  use.setAttribute('href', '#i-check');
  icon.append(use);

  const label = document.createElement('span');
  label.textContent = message;

  toastEl.append(icon, label);
  toastEl.classList.add('show');

  clearTimeout(toastTimer);
  toastTimer = setTimeout(() => toastEl.classList.remove('show'), 2000);
}

// ─── Copy buttons ────────────────────────────────────────────────────────────

/** The async clipboard is unavailable on file:// and plain http. */
async function writeClipboard(text) {
  if (navigator.clipboard && window.isSecureContext) {
    return navigator.clipboard.writeText(text);
  }

  const scratch = document.createElement('textarea');
  scratch.value = text;
  scratch.setAttribute('readonly', '');
  scratch.style.cssText = 'position:fixed;top:-9999px;opacity:0';
  document.body.append(scratch);
  scratch.select();

  try {
    if (!document.execCommand('copy')) throw new Error('copy rejected');
  } finally {
    scratch.remove();
  }
}

for (const button of document.querySelectorAll('.copy')) {
  const icon = button.querySelector('use');
  let resetTimer;

  button.addEventListener('click', async () => {
    try {
      await writeClipboard(button.dataset.copy);
    } catch {
      toast('Could not copy — select the text instead');
      return;
    }

    button.classList.add('copied');
    icon.setAttribute('href', '#i-check');
    toast(`${button.dataset.label} copied`);

    clearTimeout(resetTimer);
    resetTimer = setTimeout(() => {
      button.classList.remove('copied');
      icon.setAttribute('href', '#i-copy');
    }, 1800);
  });
}

// ─── Contact form ────────────────────────────────────────────────────────────

const form = document.getElementById('contact-form');
const submitButton = form.querySelector('.submit');
const statusEl = form.querySelector('.form-status');

/** Field name in contact.js -> the input carrying it. */
const inputs = new Map(
  FIELD_RULES.map(([field]) => [field, document.getElementById(`f-${field}`)])
);

function readValues() {
  return Object.fromEntries(
    [...inputs].map(([field, input]) => [field, input.value])
  );
}

function showError(field, message) {
  const input = inputs.get(field);
  const wrapper = input.closest('.field');

  wrapper.querySelector('.error').textContent = message ?? '';
  wrapper.classList.toggle('invalid', Boolean(message));
  input.toggleAttribute('aria-invalid', Boolean(message));
}

function paintErrors(errors) {
  for (const field of inputs.keys()) showError(field, errors[field]);
}

// Once a field has been flagged, re-check it as the visitor types so the error
// clears on the fix rather than on the next submit.
for (const [field, input] of inputs) {
  input.addEventListener('input', () => {
    if (!input.closest('.field').classList.contains('invalid')) return;
    showError(field, validate(readValues()).errors[field]);
  });
}

function setSending(sending) {
  submitButton.disabled = sending;
  submitButton.classList.toggle('sending', sending);
}

function setStatus(message, isError = false) {
  statusEl.textContent = message;
  statusEl.classList.toggle('error', isError);
}

form.addEventListener('submit', async (event) => {
  event.preventDefault();
  setStatus('');

  const values = readValues();
  const { valid, errors, firstInvalid } = validate(values);
  paintErrors(errors);

  if (!valid) {
    inputs.get(firstInvalid).focus();
    return;
  }

  setSending(true);
  try {
    await send(values);
    setStatus("Message sent — thanks, I'll be in touch.");
    form.reset();
    paintErrors({});
  } catch (error) {
    setStatus(`Could not send: ${error.message}`, true);
  } finally {
    setSending(false);
  }
});
