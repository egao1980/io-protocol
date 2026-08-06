# io-protocol

CLOS **object streams** for [cl-stack](https://github.com/egao1980/cl-stack) — Java `ObjectInput` / `ObjectOutput` shape with default **`prin1` / `read`**.

Nick: **`stack-io`**. OCI: `ghcr.io/egao1980/cl-systems/io-protocol:0.1.0`

**No serdes dependency.** Format codecs live in [`serdes-protocol`](https://github.com/egao1980/serdes-protocol). Brief: [io.md](https://github.com/egao1980/cl-stack/blob/main/docs/capabilities/io.md).

```lisp
(asdf:load-system "io-protocol")

(with-output-to-string (raw)
  (let ((out (stack-io:make-object-output-stream raw)))
    (stack-io:write-object out '(:a 1))
    (stack-io:write-object out "hi")))
;; ⇒ "(:A 1) \"hi\" "

(with-input-from-string (raw "(:A 1) \"hi\"")
  (let ((in (stack-io:make-object-input-stream raw)))
    (list (stack-io:read-object in)
          (stack-io:read-object in)
          (stack-io:read-object in))))
;; ⇒ ((:A 1) "hi" :EOF)
```

Binary streams use the same printed text via Babel UTF-8.

## License

MIT — see [LICENSE](LICENSE).
