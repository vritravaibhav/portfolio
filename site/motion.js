/**
 * Motion: entrance reveals, pointer-reactive cards, and the name decode.
 *
 * Progressive enhancement throughout. The `has-motion` class is set by a tiny
 * inline script in <head> — only then does the CSS hide anything — so if this
 * module fails to load or the visitor asked for reduced motion, the page is
 * simply the static document with everything already visible.
 */

const REDUCE_MOTION = matchMedia('(prefers-reduced-motion: reduce)').matches;

// ─── Entrance and scroll reveals ─────────────────────────────────────────────

/**
 * Elements reveal as they enter view. Those already on screen at load are
 * staggered by DOM order so the first paint resolves as one orchestrated
 * sweep rather than everything arriving at once; anything scrolled to later
 * reveals immediately, because a delay you have to wait for reads as lag.
 */
function initReveals() {
  const targets = document.querySelectorAll('[data-reveal]');
  if (!targets.length) return;

  const STAGGER_MS = 55;
  const MAX_STAGGER_MS = 620;
  let loadIndex = 0;
  let settled = false;

  // After the initial sweep, stop paying out entrance delays.
  setTimeout(() => { settled = true; }, MAX_STAGGER_MS + 250);

  const observer = new IntersectionObserver((entries) => {
    for (const entry of entries) {
      if (!entry.isIntersecting) continue;

      const delay = settled ? 0 : Math.min(loadIndex++ * STAGGER_MS, MAX_STAGGER_MS);
      entry.target.style.setProperty('--reveal-delay', `${delay}ms`);
      entry.target.classList.add('revealed');
      observer.unobserve(entry.target);          // one-shot: never re-hide
    }
  }, {
    // Fire slightly before the element reaches the fold, so the transition is
    // already running by the time it is properly in view.
    rootMargin: '0px 0px -8% 0px',
    // Any pixel entering counts. A ratio threshold silently fails on tall
    // blocks: the skills list is ~1500px, so its first 80px on screen is only
    // 5% of it and a 0.05 threshold left it stuck invisible.
    threshold: 0,
  });

  for (const target of targets) observer.observe(target);
}

// ─── Pointer-reactive cards ──────────────────────────────────────────────────

/**
 * Each card carries a highlight that tracks the pointer, driven by two custom
 * properties the stylesheet reads. One delegated listener on the container,
 * coalesced into a single rAF, keeps this off the critical path — per-card
 * listeners writing style on every pointermove is what makes this pattern
 * janky when people complain about it.
 */
function initPointerCards() {
  const scope = document.querySelector('.stream');
  if (!scope) return;

  let pending = null;

  scope.addEventListener('pointermove', (event) => {
    // Coarse pointers have no hover; the highlight would only ever flash.
    if (event.pointerType !== 'mouse') return;

    const card = event.target.closest('.card');
    if (!card) return;

    pending = { card, x: event.clientX, y: event.clientY };
    scheduleFlush();
  }, { passive: true });

  scope.addEventListener('pointerleave', () => {
    for (const card of scope.querySelectorAll('.card.lit')) card.classList.remove('lit');
  }, { passive: true });

  let frame = null;
  function scheduleFlush() {
    frame ??= requestAnimationFrame(() => {
      frame = null;
      if (!pending) return;

      const { card, x, y } = pending;
      // Reading geometry here, inside the frame, keeps the layout read out of
      // the event handler and out of the browser's input path.
      const box = card.getBoundingClientRect();
      card.style.setProperty('--pointer-x', `${((x - box.left) / box.width) * 100}%`);
      card.style.setProperty('--pointer-y', `${((y - box.top) / box.height) * 100}%`);
      card.classList.add('lit');
      pending = null;
    });
  }
}

// ─── Name decode ─────────────────────────────────────────────────────────────

const GLYPHS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/\\<>[]{}=+*#$%&@';

/**
 * Resolves each line left to right out of random glyphs.
 *
 * The real text stays in the HTML and is restored exactly, so this is purely
 * a paint-time effect — a crawler, a reader-mode view, or a failed script all
 * see the finished name. Width is pinned by the source text, so nothing
 * reflows while it runs.
 */
function decode(element, { duration = 620, delay = 0 } = {}) {
  const final = element.textContent;
  const start = performance.now() + delay;
  let frame;
  let backstop;

  function finish() {
    cancelAnimationFrame(frame);
    clearTimeout(backstop);
    element.textContent = final;                   // exact restore, always
    element.classList.add('decoded');
  }

  function tick(now) {
    const progress = Math.min(Math.max((now - start) / duration, 0), 1);
    // Ease-out, so the last characters settle rather than snapping.
    const resolved = Math.floor((1 - (1 - progress) ** 3) * final.length);

    let output = final.slice(0, resolved);
    for (let i = resolved; i < final.length; i++) {
      output += final[i] === ' '
        ? ' '
        : GLYPHS[(Math.random() * GLYPHS.length) | 0];
    }
    element.textContent = output;

    if (progress < 1) frame = requestAnimationFrame(tick);
    else finish();
  }

  // This element is the visitor's name. If the rAF loop is throttled, starved,
  // or stalled by a background tab, leaving it as random glyphs is far worse
  // than losing the effect — so a timer that cannot be starved the same way
  // guarantees the real text lands.
  backstop = setTimeout(finish, delay + duration + 400);

  frame = requestAnimationFrame(tick);
  return finish;
}

function initNameDecode() {
  const lines = document.querySelectorAll('.name .line');
  lines.forEach((line, index) => decode(line, { delay: 120 + index * 130 }));
}

// ─── Boot ────────────────────────────────────────────────────────────────────

export function initMotion() {
  // Tells the inline failsafe in <head> to stand down. Set first: if anything
  // below throws, main.js catches it and reveals everything, and we do not
  // also want the failsafe fighting over the same class.
  document.documentElement.dataset.motionReady = '1';

  if (REDUCE_MOTION) {
    // Reveal everything immediately and run nothing else.
    for (const target of document.querySelectorAll('[data-reveal]')) {
      target.classList.add('revealed');
    }
    return;
  }

  initReveals();
  initPointerCards();
  initNameDecode();
}
