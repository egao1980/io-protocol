(in-package #:io-protocol)

(define-condition io-error (error)
  ((message :initarg :message :reader io-error-message :initform nil))
  (:report (lambda (c s)
             (format s "IO error~@[: ~a~]" (io-error-message c)))))

(define-condition io-read-error (io-error) ())

(define-condition io-unimplemented (io-error) ()
  (:report (lambda (c s)
             (format s "IO operation unimplemented~@[: ~a~]"
                     (io-error-message c)))))
