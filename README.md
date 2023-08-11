[API reference](https://ocaml-multicore.github.io/thread-table/doc/thread-table/Thread_table/index.html)

# **thread-table** &mdash; A lock-free thread-safe integer keyed hash table

A high performance minimalist lock-free thread-safe integer keyed hash table
designed for associating thread specific state with threads within a domain.

⚠️ This is not _parallelism-safe_ &mdash; only _thread-safe_ within a single
domain.
