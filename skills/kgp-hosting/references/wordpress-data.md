# WordPress private data: event signups, product orders, newsletter subscribers

The content-model engine on a client's WordPress site can keep three kinds of personal data that are not posts:
event signups, product orders and a newsletter list. Each is a private table, switched on in the site's
content-model config, reachable only through manager-only `kgp/v1` routes and a wp-admin screen. A KGP site's PHP
function writes to it as a relay; the browser never talks to WordPress for these.

Use these instead of a Google Sheet, a site database or a hand-rolled store whenever a site collects signups,
orders or newsletter emails.

## Turning a module on

Add the key to the site's content-model config (GET the config, add the key, PUT it back; see
[wordpress-content.md](wordpress-content.md)). Each key is additive: turning it off later is refused.

| Module | Config key | Adds |
|---|---|---|
| Event signups | `overrides.event.signups: true` (event preset) | capacity fields on events, `kgp/v1/events/{id}/signups`, Events → Signups |
| Product orders | `overrides.product.orders: true` (product preset) | `kgp/v1/orders`, Products → Orders |
| Newsletter subscribers (engine 1.8.0) | top-level `"subscribers": true` | `kgp/v1/subscribers`, the Subscribers screen |

Who sees the data in wp-admin: Editors and Administrators for all three; the client's Site Editor login for
signups and subscribers, not orders.

## The relay

The site's PHP function calls WordPress with the Editor service account's Application Password, from two runtime
env vars the owner sets (`kgp env set NAME < file`; never ask for or print the password):

- `WP_SIGNUPS_USER`, `WP_SIGNUPS_APP_PASSWORD` (the same pair for all three modules)
- the WordPress REST base, for example `WP_API_URL=https://WP_HOST/SITE/wp-json`, or a constant in the function

Rules for every relay:

- https only, `follow_redirects => false` (never replay the credential to a redirect), a timeout of about 8 seconds.
- Never log names, emails, phones or tokens.
- Give the visitor one answer for "new" and "already there", so the form cannot be used to test who is on a list.
- Map WordPress 401, 403, 5xx and network errors to a 503 for the visitor and keep the front end's existing messages.

## Newsletter subscribers

**Signup.** `POST {WP}/kgp/v1/subscribers` with
`{email, name?, phone?, source?, consent_text}`. `consent_text` is the exact wording next to the checkbox, held as a
constant in the PHP function (never sent by the browser). Answers: `201` new, `200` already on the list (with
`resubscribed: true` when an unsubscribed person signed up again), `400 kgp_subscriber_invalid` with `data.field`.
The form's consent checkbox stays unticked by default and required.

**Unsubscribe.** Every subscriber has a private token. The site needs:

- a page such as `/unsubscribe?t=TOKEN` that shows a button and POSTs on click, never on page load (mail scanners
  open links), marked `noindex` and left out of the sitemap;
- a PHP function, for example `functions/unsubscribe.php`, that checks the token is 48 hex characters, rate-limits,
  and POSTs `{token}` to the public `{WP}/kgp/v1/subscribers/unsubscribe`. That route answers the same `200` for
  every well-formed token, so the page always says "You're unsubscribed".

Then the client (or owner) sets the page's https address under Subscribers → Unsubscribe page in wp-admin.

**Campaigns.** The platform does not send newsletters (kgp-mail is for transactional mail). The client exports
the list (Subscribers → Export CSV) to Mailchimp, MailerLite or Brevo and puts the `unsubscribe_url` column in
every email as a merge field. Unsubscribes made in the email service come back through Import CSV: rows marked
unsubscribed or cleaned unsubscribe the matching people. An import never adds someone who opted out and never
resubscribes anyone.

**Moving an existing list in.** Deploy the new relay first, then export the old list (a Google Sheet:
File → Download → CSV) and import it. Emails already on the list are skipped, so nothing is lost or doubled.

## Event signups and product orders

- Signups: `POST {WP}/kgp/v1/events/{id}/signups` `{name, email, phone?, spaces?, source?}` → `201` with the event
  summary for the confirmation email, `200 {duplicate: true}`, `409 full | closed`, `404`. Capacity is enforced in
  WordPress; never count spaces in the site.
- Orders: `POST {WP}/kgp/v1/orders` from the payment webhook only (server to server), keyed by the checkout
  session id, so retries are a `200` no-op.

## Never

- Read or export these lists for the user unasked; they hold personal data. Point the client to the wp-admin
  screen instead.
- Store a list in a site database, a JSON file in the release, or browser storage.
- Send bulk mail with `kgp_send_email()`.
