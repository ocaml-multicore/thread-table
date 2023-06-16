[API reference](https://ocaml-multicore.github.io/thread-table/doc/thread-table/Thread_table/index.html)

# **thread-table** &mdash; A lock-free thread-safe integer keyed hash table

This experimental library implements a minimalist lock-free thread-safe integer
keyed hash table.

⚠️ This is not _domain-safe_ &mdash; only _thread-safe_ within a single domain.
