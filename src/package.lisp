(defpackage #:io-protocol
  (:use #:cl)
  (:nicknames #:stack-io)
  (:export #:io-error
           #:io-read-error
           #:io-unimplemented
           #:io-error-message
           #:object-input-stream
           #:object-output-stream
           #:binary-object-input-stream
           #:binary-object-output-stream
           #:character-object-input-stream
           #:character-object-output-stream
           #:read-object
           #:write-object
           #:make-object-input-stream
           #:make-object-output-stream
           #:underlying-stream))

(in-package #:io-protocol)
