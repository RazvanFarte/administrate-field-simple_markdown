# Performance

Two questions decide how you use this field: **how long a document can it
carry**, and **how many editors can go on one form**. Both are measured here
rather than estimated, with the scripts in `bench/`.

Everything below was measured on an AMD Ryzen 7 3750H (7 cores available),
8 GB RAM, WSL2 on Windows, Ruby 4.0.6, Redcarpet 3.6.1, PostgreSQL 18.6, and
headless Chromium 1200 from the Playwright container. Treat the absolute
numbers as a shape, not a promise: reproduce them on your own hardware with
`rake bench:redcarpet`, `rake bench:postgres` and `rake bench:browser`.

The Markdown corpus is generated prose - headings, paragraphs, emphasis, links,
lists and quotes, assembled from a word list with a seeded PRNG. An earlier
version of the corpus repeated one paragraph, which made Postgres look 25x
better at compression than it really is; do not swap it for `"a" * n`.

## Short answer

| Question | Answer |
|---|---|
| How many characters can Redcarpet handle? | Far more than you want in a form field. 10,000 characters renders to HTML in **0.14 ms**; 1,000,000 takes **12 ms**. There is no practical parser limit. |
| So what limits document length? | The browser. A 10,000-character document costs roughly **870 DOM nodes** and **~19 ms** of editor setup. **10,000-20,000 characters is a comfortable ceiling**, which matches the 5-10k you had in mind for rich text. |
| How many editors on one form? | **10 is comfortable, 20 is the practical ceiling.** Twenty editors holding 10,000 characters each reach ready in **471 ms** and build a 17,000-node page. |
| What does Postgres care about? | Nothing at these sizes. A `text` column holds 1 GB; 10,000 characters of Markdown compresses to about **3 KB** on disk and reads back in **0.9 ms**. |

## Server: Redcarpet rendering

`rake bench:redcarpet`, 200 iterations per size, a fresh field object each time
because Administrate builds one per row per request.

| Document | `#to_html` (show page) | `#to_s` (full strip) | `#preview` (index page) | throughput |
|---|---|---|---|---|
| 1,000 chars | 0.077 ms | 0.048 ms | 0.044 ms | 12,900 chars/ms |
| 5,000 chars | 0.088 ms | 0.224 ms | 0.046 ms | 56,600 chars/ms |
| 10,000 chars | 0.144 ms | 0.264 ms | 0.035 ms | 69,400 chars/ms |
| 50,000 chars | 0.581 ms | 1.270 ms | 0.045 ms | 86,100 chars/ms |
| 100,000 chars | 1.239 ms | 2.679 ms | 0.044 ms | 80,700 chars/ms |
| 1,000,000 chars | 12.440 ms | 27.404 ms | 0.052 ms | 80,400 chars/ms |

Redcarpet is a C extension and it shows: cost is linear in document length at
about 80,000 characters per millisecond once past the fixed per-field overhead,
which is roughly 0.04 ms of object construction. Small documents are dominated
by that fixed cost, which is why the 1,000-character row looks inefficient per
character and is still the fastest row in absolute terms.

**Nothing here is a reason to restrict document length.** Even a megabyte
renders in 12 ms, which is less than a typical database round trip.

### Why `#preview` is flat

`#preview` does not change with document size, because it strips a slice of the
Markdown source instead of rendering the whole document and throwing the result
away. That matters on index pages, where the work is multiplied by rows times
columns:

| Document per cell | Markdown columns | 25 rows, `#preview` | 25 rows, `#to_s` (what 0.7.0 did) |
|---|---|---|---|
| 1,000 chars | 1 | 1.1 ms | 1.2 ms |
| 1,000 chars | 3 | 3.3 ms | 3.6 ms |
| 1,000 chars | 5 | 5.5 ms | 6.0 ms |
| 10,000 chars | 1 | 0.9 ms | 6.6 ms |
| 10,000 chars | 3 | 2.7 ms | 19.8 ms |
| 10,000 chars | 5 | 4.4 ms | 33.0 ms |

At 1,000 characters the two are the same within noise. At 10,000 the old path
costs 7x more, and it keeps growing while `#preview` does not.

The slice is `max(truncate_length * 4, 256)` characters, generous because
stripping Markdown shrinks text - `[link](https://example.com/a/path)` is 34
characters of source and 4 of output. A document that is almost entirely link
syntax can therefore produce a shorter preview than a full render would. Set
`preview_source_limit: nil` to render the whole document, or a number to control
the slice yourself.

## Browser: how many editors fit on a form

`rake bench:browser`, median of 3 navigations per row, asset cache warm.
"All editors ready" is measured inside the page, from navigation start to the
moment the last `.EasyMDEContainer` exists.

| Content | Editors | DOMContentLoaded | All editors ready | DOM nodes |
|---|---|---|---|---|
| empty | 1 | 124 ms | 124 ms | 116 |
| empty | 3 | 176 ms | 175 ms | 244 |
| empty | 5 | 183 ms | 182 ms | 372 |
| empty | 10 | 157 ms | 155 ms | 693 |
| empty | 20 | 216 ms | 213 ms | 1,332 |
| 10,000 chars each | 1 | 117 ms | 116 ms | 921 |
| 10,000 chars each | 3 | 205 ms | 204 ms | 2,655 |
| 10,000 chars each | 5 | 227 ms | 225 ms | 4,389 |
| 10,000 chars each | 10 | 293 ms | 290 ms | 8,724 |
| 10,000 chars each | 20 | 476 ms | 471 ms | 17,394 |

Read the **slope**, not a per-editor average - dividing a page total by the
editor count charges each editor a share of the fixed ~110 ms page cost.

- **An empty editor costs about 4.7 ms** and 64 DOM nodes.
- **An editor holding 10,000 characters costs about 19 ms** and 870 DOM nodes.

CodeMirror only renders the lines in view, so node count grows with the editor's
viewport rather than with the whole document; the content still has to be
parsed and highlighted, which is where the time goes.

JS heap was recorded too and is omitted from the table on purpose: Chromium
reports it in coarse buckets and it did not vary meaningfully between 1 and 20
editors, so it would only look like a signal.

### Recommendation

- **Up to 10 Markdown fields on a form** keeps the page under ~300 ms to
  interactive with realistic content. This is the range to design for.
- **20 is the practical ceiling.** Just under half a second and a 17,000-node
  document is usable but no longer pleasant, and it is where an admin on a
  slower laptop starts to notice.
- Beyond that, put the fields on separate tabs or pages rather than accepting
  the cost. Administrate makes this cheap: split `FORM_ATTRIBUTES` across
  `FORM_ATTRIBUTES_NEW` and `FORM_ATTRIBUTES_EDIT`, or give the long-form
  content its own dashboard.
- The bundle itself is one JavaScript file (348 KB raw, **114 KB gzipped**) and
  one stylesheet (55 KB raw, **8 KB gzipped**), fetched once per browser and
  cached. It is a fixed cost per page, not per editor, and it does not change
  with the number of fields. Most of the JavaScript is CodeMirror; DOMPurify
  adds about 23 KB raw, and the bundled toolbar icons account for roughly
  42 KB of the stylesheet - which is still less than the Font Awesome
  stylesheet 0.7.0 fetched from a CDN, and it costs no extra request.

## Postgres: storage and round trip

`rake bench:postgres`, 50 iterations per size against PostgreSQL 18 in Docker.
`pg_column_size` is the on-disk size after TOAST compression.

| Document | Raw bytes | Stored bytes | Compression | INSERT | SELECT |
|---|---|---|---|---|---|
| 1,000 chars | 1,000 | 1,004 | 1.0x | 1.86 ms | 0.60 ms |
| 5,000 chars | 5,000 | 1,797 | 2.8x | 2.10 ms | 0.87 ms |
| 10,000 chars | 10,000 | 3,092 | 3.2x | 2.82 ms | 0.91 ms |
| 50,000 chars | 50,000 | 13,573 | 3.7x | 3.81 ms | 1.28 ms |
| 100,000 chars | 100,000 | 26,603 | 3.8x | 6.17 ms | 1.70 ms |
| 1,000,000 chars | 1,000,000 | 259,709 | 3.9x | 32.29 ms | 9.58 ms |

What the numbers say:

- **A `text` column holds 1 GB.** There is nothing to configure: `text`,
  `varchar` and `varchar(n)` store identically in Postgres, and `n` only adds a
  length check. Use `text`.
- **Values over about 2 KB move out of the row into TOAST storage and are
  compressed.** That is why 1,000 characters stores at 1.0x - it stays inline -
  while everything larger compresses to roughly a third. A 10,000-character
  document costs about **3 KB** on disk.
- **Round trips stay in single-digit milliseconds** right up to a megabyte, so
  storage is not the constraint at any size you would put in a form.

The one thing to watch is `SELECT *` on an index page: TOASTed columns are only
fetched when the column is actually read, so listing a Markdown column on the
index page pulls every document out of TOAST storage for every row. If an index
page feels slow, drop the Markdown column from `COLLECTION_ATTRIBUTES` before
looking anywhere else.

## Practical limits, in one place

| | Comfortable | Ceiling | What breaks first |
|---|---|---|---|
| Characters per field | 10,000 | 100,000 | Editor setup time and DOM size in the browser. Redcarpet and Postgres are nowhere near their limits. |
| Markdown fields per form | 10 | 20 | Time to interactive on the form page. |
| Markdown columns on an index page | 3 | 5 | TOAST reads and row count, not rendering - `#preview` keeps the render cost flat. |

None of these are enforced by the gem. If you need a hard limit, add a model
validation:

```ruby
validates :body, length: { maximum: 20_000 }
```
