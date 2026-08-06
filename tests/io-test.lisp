(in-package #:io-protocol/tests)

(deftest character-round-trip
  (let ((raw (with-output-to-string (o)
               (let ((out (make-object-output-stream o)))
                 (write-object out '(:a 1))
                 (write-object out "hi")))))
    (ok (search "(:A 1)" raw))
    (with-input-from-string (i raw)
      (let ((in (make-object-input-stream i)))
        (ok (equal '(:a 1) (read-object in)))
        (ok (string= "hi" (read-object in)))
        (ok (eq :eof (read-object in)))))))

(deftest gray-pass-through-char
  (with-output-to-string (o)
    (let ((out (make-object-output-stream o)))
      (write-char #\Z out)
      (write-object out 42)))
  (with-input-from-string (i "Z 99 ")
    (let ((in (make-object-input-stream i)))
      (ok (char= #\Z (read-char in)))
      (ok (= 99 (read-object in))))))

(defclass %byte-vector-output-stream
    (trivial-gray-streams:fundamental-binary-output-stream)
  ((buffer :initform (make-array 0 :element-type '(unsigned-byte 8)
                                 :adjustable t :fill-pointer 0)
           :accessor %buf)))

(defmethod stream-element-type ((s %byte-vector-output-stream))
  '(unsigned-byte 8))

(defmethod trivial-gray-streams:stream-write-byte ((s %byte-vector-output-stream) byte)
  (vector-push-extend byte (%buf s))
  byte)

(defclass %byte-vector-input-stream
    (trivial-gray-streams:fundamental-binary-input-stream)
  ((buffer :initarg :buffer :reader %buf)
   (pos :initform 0 :accessor %pos)))

(defmethod stream-element-type ((s %byte-vector-input-stream))
  '(unsigned-byte 8))

(defmethod trivial-gray-streams:stream-read-byte ((s %byte-vector-input-stream))
  (if (>= (%pos s) (length (%buf s)))
      :eof
      (prog1 (aref (%buf s) (%pos s))
        (incf (%pos s)))))

(defmethod trivial-gray-streams:stream-read-sequence
    ((s %byte-vector-input-stream) seq start end &key)
  (loop for i from start below end
        for b = (trivial-gray-streams:stream-read-byte s)
        until (eq b :eof)
        do (setf (aref seq i) b)
        finally (return i)))

(deftest binary-round-trip
  (let ((sink (make-instance '%byte-vector-output-stream)))
    (let ((out (make-object-output-stream sink :element-type '(unsigned-byte 8))))
      (write-object out '(:x 2))
      (write-object out 7))
    (let* ((bytes (copy-seq (%buf sink)))
           (src (make-instance '%byte-vector-input-stream :buffer bytes))
           (in (make-object-input-stream src :element-type '(unsigned-byte 8))))
      (ok (equal '(:x 2) (read-object in)))
      (ok (= 7 (read-object in)))
      (ok (eq :eof (read-object in))))))

(defclass %unimplemented-out (character-object-output-stream) ())

(defmethod write-object ((s %unimplemented-out) object &key)
  (declare (ignore object))
  (error 'io-unimplemented :message "disabled"))

(deftest unimplemented-signals
  (ok (signals (write-object (make-instance '%unimplemented-out
                                            :underlying (make-string-output-stream))
                             1)
               'io-unimplemented)))
