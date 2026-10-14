# Site analytics on KGP Host (self-hosted Matomo)

One Matomo On-Premise per KGP Host instance collects page analytics for every site, at a stats host of the
owner's own domain (for example `https://stats.example.com`). It is cookieless: no consent banner is needed. The
owner installs it once with `kgp analytics install`; agents usually only add sites and the snippet.

## Add a site

Inside the site's repo (the folder with `kgp.toml`):

```sh
kgp analytics add-site --json --yes          # creates or finds the Matomo site; writes [analytics] site_id to kgp.toml
kgp analytics snippet --format js --json --yes
```

`add-site` is safe to re-run: it reuses the Matomo site whose main URL is `https://SITE.PLATFORM_DOMAIN/` and adds
the site's custom domains as alias URLs. Commit the `[analytics] site_id` line; it is not a secret.

## The snippet in a React app

`kgp analytics snippet --format js --json --yes` returns `{snippet}`: a script that loads `https://stats.example.com/matomo.js`,
turns cookies off, respects Do Not Track, and tracks every route change (it listens to `pushState`, `replaceState`
and `popstate`, so React Router navigation counts as page views). Save it as `src/analytics.ts` (or `.js`) and import
it once from the app entry:

```ts
import "./analytics";
```

`--format html` prints a `<script>` block for `index.html` instead. Only load it in production builds if the site
has preview deploys you do not want counted.

## Content-Security-Policy

When a site with `[analytics] site_id` is deployed, kgp appends the stats origin to `script-src`, `connect-src` and
`img-src` of the site's own `Content-Security-Policy` (from `kgp.toml` `[headers]` or a `/*` rule in `_headers`). A
missing directive starts as a copy of `default-src`; a policy without `default-src` and without the directive is left
alone. Sites without a CSP are unchanged; kgp never adds one. With a strict CSP, use `--format js` (a bundled module):
the inline `--format html` snippet would also need `'unsafe-inline'` or a hash in `script-src`.

## WordPress (Connect Matomo)

WordPress sites report to the same Matomo through the Connect Matomo plugin, network-activated on multisite. Each
subsite gets its own Matomo site (`kgp analytics add-site --wordpress https://example.org/client/ --json --yes`) and
sees only its own statistics. The plugin uses the view-only Matomo user `wp-connect`, whose token the owner creates
with `kgp analytics wp-token` and pastes into the network settings. Never ask for that token or paste it anywhere.

## Privacy defaults

IP addresses are masked by 2 bytes before storage, Do Not Track is respected, raw visit logs are deleted after 180
days (reports are kept), and the tracker sets no cookies. These are set by `kgp analytics install`; do not change
them in Matomo without the owner.

## Owner-only commands

`kgp analytics configure`, `install`, `upgrade`, `add-site --wordpress`, `wp-token` and `invite` change the shared
Matomo or create access. Run them only when the owner asks. `kgp analytics status --json --yes` is always safe.
