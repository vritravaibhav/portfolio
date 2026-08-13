# portfolio

[![Deploy](https://github.com/vritravaibhav/portfolio/actions/workflows/deploy.yml/badge.svg)](https://github.com/vritravaibhav/portfolio/actions/workflows/deploy.yml)

Personal site — <https://vritravaibhav.github.io/portfolio/>

Static HTML, CSS and a little JavaScript. No framework, no build step, no
runtime dependencies.

## Why it isn't Flutter any more

The site was originally a Flutter web app. Flutter renders through CanvasKit,
which paints the entire page into a single `<canvas>` — so a crawler fetching
the URL received a title, a meta description, and an empty body. None of the
actual content existed in the DOM.

That used to be fixable with `--web-renderer html`, which emitted real text
nodes. Flutter 3.29 deprecated that renderer and 3.32 removed it, so there is
no longer a flag that makes a Flutter web app indexable. Leaving the canvas
was the only remaining option.

Rewriting it as markup also fixed the things the canvas broke along the way:

| | Flutter | Static |
| --- | --- | --- |
| Cold load | ~3–4 MB compressed | ~114 KB |
| Indexable text | 0 words | ~805 words |
| Text selection / `Ctrl+F` | no | yes |
| Screen readers | canvas semantics only | real document |
| Link previews | none | Open Graph + Twitter |
| CI | Flutter SDK + build | upload `site/` |

LLM crawlers matter here too: they don't execute JavaScript at all, so a
canvas-rendered page is invisible to them regardless of how patient Googlebot
is willing to be.

## Layout

    site/                 everything that gets published
      index.html          all content, as markup
      styles.css          design tokens and layout
      contact.js          form logic — pure functions, no DOM, no network
      main.js             DOM wiring only
      fonts/              self-hosted Syne + IBM Plex subsets
        regenerate.py     re-downloads them from Google Fonts

    test/contact.test.js  unit tests for contact.js
    scripts/check-site.js pre-deploy checks over site/

## Running it

    npm run serve         # http://localhost:8000
    npm run verify        # tests + site checks

Node 20+. There is nothing to install — `npm test` uses Node's built-in test
runner and the checks use only the standard library.

## Quality gates

With no build step, nothing would otherwise catch a renamed asset or a dropped
meta tag until it was live. CI runs both suites on every push and pull request,
and `deploy` only runs if they pass.

`npm test` — 31 unit tests over `site/contact.js`. The valuable ones pin the
Firestore payload: the `mail` document shape is dictated by the Firebase
Trigger Email extension, and a wrong field name there fails silently at send
time rather than loudly at build time. Nondeterminism (document IDs, `fetch`)
is injected, so the exact request body is assertable.

`npm run check` — 12 checks over `site/`:

- markup balances, and every form field has a `<label>`
- every local `href`/`src`/`url()` resolves on disk, including the module graph
- the SEO contract holds: title, description, canonical, Open Graph, Twitter
  card, valid `Person` JSON-LD, and `robots.txt`/`sitemap.xml` agreeing with
  the canonical origin
- the page still carries real text (word count plus load-bearing terms), so it
  can't silently degrade into a shell
- a cold load stays inside a 200 KB budget, itemised per file when it doesn't
- no font is shipped that `fonts.css` doesn't reference, and no weight is used
  that no `@font-face` provides

Each check has been verified to fail when its invariant is broken, not just to
pass when everything is fine.

## Contact form

Posts straight to the Firestore REST API, writing one document to `form` (the
submission log) and one to `mail`, which the Firebase "Trigger Email from
Firestore" extension picks up and delivers.

Both writes go in a single atomic commit, so the log and the queued email can't
diverge — an improvement over the Flutter version, which issued two sequential
writes. Each write is a create (`currentDocument: {exists: false}`), so an ID
collision fails loudly instead of overwriting a record, and `createdAt` is set
by the server rather than trusting the client clock.

The Web API key in `contact.js` is not a secret. It identifies the project
rather than authorising anything, it was already public inside the old Flutter
bundle, and every write is governed by the Firestore security rules.

## Deploying

`.github/workflows/deploy.yml` publishes `site/` to GitHub Pages on every push
to `main` that passes the gates above. All paths inside the page are relative,
so it deploys as-is under the `/portfolio/` subpath Pages serves from.
