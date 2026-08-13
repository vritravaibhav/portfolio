# portfolio

Personal site — <https://vritravaibhav.github.io/portfolio/>

## Layout

    site/            the published site (static HTML/CSS/JS, no build step)
      index.html     all content lives here as real markup
      styles.css     design tokens + layout
      main.js        copy buttons and the contact form
      fonts/         self-hosted Syne + IBM Plex subsets
        regenerate.py  re-downloads them from Google Fonts

    lib/, web/       the previous Flutter implementation (no longer deployed)

## Running it

    python3 -m http.server 8000 --directory site

## Deploying

`.github/workflows/deploy.yml` publishes `site/` to GitHub Pages on every push
to `main`. There is no build step — the workflow uploads the directory as-is.
All paths inside the page are relative, so it works unchanged under the
`/portfolio/` subpath Pages serves from.

## Contact form

Posts straight to the Firestore REST API (project `port-fol-io`), writing one
document to `form` (the submission log) and one to `mail`, which the Firebase
"Trigger Email from Firestore" extension picks up and delivers. Both writes go
in a single atomic commit.

The Web API key in `main.js` is not a secret — it identifies the project and
was already public in the old Flutter bundle. Access is governed by the
Firestore security rules.
