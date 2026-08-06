(defsystem "io-protocol"
  :version "0.1.0"
  :description "CLOS object streams for cl-stack — ObjectInput/Output with default prin1/read (no serdes)"
  :author "egao1980"
  :license "MIT"
  :depends-on ("trivial-gray-streams" "babel")
  :serial t
  :pathname "src"
  :components ((:file "package")
               (:file "conditions")
               (:file "protocol"))
  :in-order-to ((test-op (test-op "io-protocol/tests"))))

(defsystem "io-protocol/tests"
  :depends-on ("io-protocol" "rove")
  :pathname "tests"
  :serial t
  :components ((:file "package")
               (:file "io-test"))
  :perform (test-op (o c)
             (unless (symbol-call :rove :run c)
               (error "tests failed for ~A" (component-name c)))))
