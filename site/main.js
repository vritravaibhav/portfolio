/* ============================================================================
   Copy buttons + contact form.

   The form writes straight to the Firestore REST API — same project, same two
   collections, same shape as the Flutter build did through cloud_firestore.
   `mail` is consumed by the "Trigger Email from Firestore" extension.

   The Web API key below is not a secret: it identifies the project, it was
   already shipped inside main.dart.js, and access is governed by Firestore
   security rules exactly as before.
   ========================================================================= */

(function () {
  'use strict';

  var PROJECT_ID = 'port-fol-io';
  var API_KEY = 'AIzaSyDpbsuZ6GMrAOX7dZNqwlgftpsOySXSg8g';
  var CONTACT_EMAIL = 'divaibhavyanshu@gmail.com';

  var COMMIT_URL =
    'https://firestore.googleapis.com/v1/projects/' + PROJECT_ID +
    '/databases/(default)/documents:commit?key=' + API_KEY;
  var DOC_ROOT =
    'projects/' + PROJECT_ID + '/databases/(default)/documents/';

  // ─── Toast ───────────────────────────────────────────────────────────────

  var toastEl = document.querySelector('.toast');
  var toastTimer = null;

  function toast(message) {
    toastEl.innerHTML =
      '<svg class="ico" aria-hidden="true"><use href="#i-check"/></svg>' +
      '<span></span>';
    toastEl.querySelector('span').textContent = message;
    toastEl.classList.add('show');

    clearTimeout(toastTimer);
    toastTimer = setTimeout(function () {
      toastEl.classList.remove('show');
    }, 2000);
  }

  // ─── Copy buttons ────────────────────────────────────────────────────────

  function writeClipboard(text) {
    if (navigator.clipboard && window.isSecureContext) {
      return navigator.clipboard.writeText(text);
    }
    // file:// and plain http have no async clipboard.
    return new Promise(function (resolve, reject) {
      var ta = document.createElement('textarea');
      ta.value = text;
      ta.setAttribute('readonly', '');
      ta.style.cssText = 'position:fixed;top:-9999px;opacity:0';
      document.body.appendChild(ta);
      ta.select();
      var ok = false;
      try { ok = document.execCommand('copy'); } catch (e) { ok = false; }
      document.body.removeChild(ta);
      ok ? resolve() : reject(new Error('copy failed'));
    });
  }

  Array.prototype.forEach.call(
    document.querySelectorAll('.copy'),
    function (btn) {
      var use = btn.querySelector('use');
      var resetTimer = null;

      btn.addEventListener('click', function () {
        writeClipboard(btn.dataset.copy).then(function () {
          btn.classList.add('copied');
          use.setAttribute('href', '#i-check');
          toast(btn.dataset.label + ' copied');

          clearTimeout(resetTimer);
          resetTimer = setTimeout(function () {
            btn.classList.remove('copied');
            use.setAttribute('href', '#i-copy');
          }, 1800);
        }).catch(function () {
          toast('Could not copy — select the text instead');
        });
      });
    }
  );

  // ─── Firestore value encoding ────────────────────────────────────────────

  function str(s) { return { stringValue: s }; }

  function strArray(list) {
    return { arrayValue: { values: list.map(str) } };
  }

  function map(fields) { return { mapValue: { fields: fields } }; }

  // Firestore auto-IDs: 20 chars of [A-Za-z0-9].
  function autoId() {
    var alphabet =
      'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    var bytes = new Uint8Array(20);
    crypto.getRandomValues(bytes);
    var id = '';
    for (var i = 0; i < 20; i++) id += alphabet[bytes[i] % alphabet.length];
    return id;
  }

  // Mirrors _esc() in the Dart original.
  function esc(s) {
    return s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
  }

  // ─── Form ────────────────────────────────────────────────────────────────

  var form = document.getElementById('contact-form');
  var submitBtn = form.querySelector('.submit');
  var statusEl = form.querySelector('.form-status');

  var RULES = {
    'f-name': function (v) {
      return v ? null : 'Please enter your name';
    },
    'f-email': function (v) {
      if (!v) return 'Please enter your email';
      return /^[^@]+@[^@]+\.[^@]+/.test(v) ? null : 'Please enter a valid email';
    },
    'f-subject': function (v) {
      return v ? null : 'Please enter the subject';
    },
    'f-message': function (v) {
      return v ? null : 'Please enter your message';
    }
  };

  function setError(id, message) {
    var input = document.getElementById(id);
    var field = input.closest('.field');
    var errorEl = field.querySelector('.error');

    errorEl.textContent = message || '';
    field.classList.toggle('invalid', !!message);
    if (message) {
      input.setAttribute('aria-invalid', 'true');
    } else {
      input.removeAttribute('aria-invalid');
    }
  }

  function validate() {
    var firstBad = null;
    Object.keys(RULES).forEach(function (id) {
      var value = document.getElementById(id).value.trim();
      var message = RULES[id](value);
      setError(id, message);
      if (message && !firstBad) firstBad = id;
    });
    if (firstBad) document.getElementById(firstBad).focus();
    return !firstBad;
  }

  // Re-validate a field once it has been marked bad, so the error clears as
  // soon as the visitor fixes it rather than on the next submit.
  Object.keys(RULES).forEach(function (id) {
    var input = document.getElementById(id);
    input.addEventListener('input', function () {
      if (input.closest('.field').classList.contains('invalid')) {
        setError(id, RULES[id](input.value.trim()));
      }
    });
  });

  function setSending(sending) {
    submitBtn.disabled = sending;
    submitBtn.classList.toggle('sending', sending);
  }

  form.addEventListener('submit', function (event) {
    event.preventDefault();
    statusEl.textContent = '';
    statusEl.classList.remove('error');

    if (!validate()) return;

    var name = document.getElementById('f-name').value.trim();
    var email = document.getElementById('f-email').value.trim();
    var subject = document.getElementById('f-subject').value.trim();
    var message = document.getElementById('f-message').value.trim();

    setSending(true);

    var html =
      '<p><strong>From:</strong> ' + esc(name) +
      ' (<a href="mailto:' + esc(email) + '">' + esc(email) + '</a>)</p>' +
      '<p><strong>Subject:</strong> ' + esc(subject) + '</p>' +
      '<hr>' +
      '<p>' + esc(message).replace(/\n/g, '<br>') + '</p>';

    // Both documents go in a single atomic commit: the raw submission log and
    // the queued notification email either both land or neither does.
    var body = {
      writes: [
        {
          update: {
            name: DOC_ROOT + 'form/' + autoId(),
            fields: {
              name: str(name),
              email: str(email),
              subject: str(subject),
              description: str(message)
            }
          },
          // Equivalent to FieldValue.serverTimestamp() in the Dart version.
          updateTransforms: [
            { fieldPath: 'createdAt', setToServerValue: 'REQUEST_TIME' }
          ],
          currentDocument: { exists: false }
        },
        {
          update: {
            name: DOC_ROOT + 'mail/' + autoId(),
            fields: {
              to: strArray([CONTACT_EMAIL]),
              replyTo: str(email),
              message: map({
                subject: str('Portfolio enquiry: ' + subject),
                text: str(
                  'From: ' + name + ' <' + email + '>\n' +
                  'Subject: ' + subject + '\n\n' +
                  message
                ),
                html: str(html)
              })
            }
          },
          currentDocument: { exists: false }
        }
      ]
    };

    fetch(COMMIT_URL, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    }).then(function (response) {
      if (response.ok) return response.json();
      return response.json().then(
        function (payload) {
          throw new Error(
            (payload && payload.error && payload.error.message) ||
            ('HTTP ' + response.status)
          );
        },
        function () { throw new Error('HTTP ' + response.status); }
      );
    }).then(function () {
      statusEl.textContent = "Message sent — thanks, I'll be in touch.";
      form.reset();
      Object.keys(RULES).forEach(function (id) { setError(id, null); });
    }).catch(function (error) {
      statusEl.classList.add('error');
      statusEl.textContent = 'Could not send: ' + error.message;
    }).finally(function () {
      setSending(false);
    });
  });
})();
