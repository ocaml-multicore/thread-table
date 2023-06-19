[API reference](https://ocaml-multicore.github.io/thread-table/doc/thread-table/Thread_table/index.html)

# **thread-table** &mdash; A lock-free thread-safe integer keyed hash table

This experimental library implements a minimalist lock-free thread-safe integer
keyed hash table.

⚠️ This is not _domain-safe_ &mdash; only _thread-safe_ within a single domain.

## Development

### Formatting

This project uses [ocamlformat](https://github.com/ocaml-ppx/ocamlformat) (for
OCaml) and [prettier](https://prettier.io/) (for Markdown).

### To make a new release

1. Update [CHANGES.md](CHANGES.md).
2. Run `dune-release tag VERSION` to create a tag for the new `VERSION`.
3. Run `dune-release` to publish the new `VERSION`.
4. Run `./update-gh-pages-for-tag VERSION` to update the online documentation.
