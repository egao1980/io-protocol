(in-package #:io-protocol)

;;;; Object streams — Gray pass-through + default prin1/read (no serdes).

(defclass object-input-stream ()
  ((underlying :initarg :underlying :reader underlying-stream)))

(defclass object-output-stream ()
  ((underlying :initarg :underlying :reader underlying-stream)))

(defclass character-object-input-stream
    (object-input-stream trivial-gray-streams:fundamental-character-input-stream)
  ())

(defclass character-object-output-stream
    (object-output-stream trivial-gray-streams:fundamental-character-output-stream)
  ())

(defclass binary-object-input-stream
    (object-input-stream trivial-gray-streams:fundamental-binary-input-stream)
  ((pending :initform "" :accessor %binary-pending)))

(defclass binary-object-output-stream
    (object-output-stream trivial-gray-streams:fundamental-binary-output-stream)
  ())

;;; Gray pass-through — character

(defmethod trivial-gray-streams:stream-read-char ((s character-object-input-stream))
  (read-char (underlying-stream s) nil :eof))

(defmethod trivial-gray-streams:stream-unread-char ((s character-object-input-stream) char)
  (unread-char char (underlying-stream s)))

(defmethod trivial-gray-streams:stream-listen ((s character-object-input-stream))
  (listen (underlying-stream s)))

(defmethod trivial-gray-streams:stream-write-char ((s character-object-output-stream) char)
  (write-char char (underlying-stream s)))

(defmethod trivial-gray-streams:stream-line-column ((s character-object-output-stream))
  (ignore-errors (trivial-gray-streams:stream-line-column (underlying-stream s))))

(defmethod trivial-gray-streams:stream-finish-output ((s character-object-output-stream))
  (finish-output (underlying-stream s)))

(defmethod trivial-gray-streams:stream-force-output ((s character-object-output-stream))
  (force-output (underlying-stream s)))

(defmethod close ((s object-input-stream) &key abort)
  (close (underlying-stream s) :abort abort))

(defmethod close ((s object-output-stream) &key abort)
  (close (underlying-stream s) :abort abort))

;;; Gray pass-through — binary

(defmethod stream-element-type ((s binary-object-input-stream))
  '(unsigned-byte 8))

(defmethod stream-element-type ((s binary-object-output-stream))
  '(unsigned-byte 8))

(defmethod stream-element-type ((s character-object-input-stream))
  'character)

(defmethod stream-element-type ((s character-object-output-stream))
  'character)

(defmethod trivial-gray-streams:stream-read-byte ((s binary-object-input-stream))
  (read-byte (underlying-stream s) nil :eof))

(defmethod trivial-gray-streams:stream-write-byte ((s binary-object-output-stream) byte)
  (write-byte byte (underlying-stream s)))

(defmethod trivial-gray-streams:stream-finish-output ((s binary-object-output-stream))
  (finish-output (underlying-stream s)))

(defmethod trivial-gray-streams:stream-force-output ((s binary-object-output-stream))
  (force-output (underlying-stream s)))

;;; Object I/O

(defgeneric write-object (stream object &key)
  (:documentation "Write OBJECT. Default: prin1 + space separator."))

(defgeneric read-object (stream &key)
  (:documentation "Read one object. Default: plain READ; EOF → :eof."))

(defmethod write-object ((s character-object-output-stream) object &key)
  (let ((u (underlying-stream s)))
    (prin1 object u)
    (write-char #\Space u)
    object))

(defmethod read-object ((s character-object-input-stream) &key)
  (handler-case
      (read (underlying-stream s))
    (end-of-file ()
      :eof)
    (reader-error (e)
      (error 'io-read-error :message (princ-to-string e)))))

(defun %binary-write-text (stream text)
  (let ((octets (babel:string-to-octets text :encoding :utf-8))
        (u (underlying-stream stream)))
    (loop for b across octets do (write-byte b u))))

(defmethod write-object ((s binary-object-output-stream) object &key)
  (let ((text (with-output-to-string (o)
                (prin1 object o)
                (write-char #\Space o))))
    (%binary-write-text s text)
    object))

(defun %binary-refill (s)
  "Append decoded UTF-8 from underlying into PENDING. Returns T if any bytes read."
  (let* ((u (underlying-stream s))
         (chunk (make-array 4096 :element-type '(unsigned-byte 8)))
         (n (read-sequence chunk u)))
    (when (plusp n)
      (setf (%binary-pending s)
            (concatenate 'string
                         (%binary-pending s)
                         (babel:octets-to-string chunk :end n :encoding :utf-8)))
      t)))

(defmethod read-object ((s binary-object-input-stream) &key)
  (loop
    (when (and (zerop (length (%binary-pending s)))
               (not (%binary-refill s)))
      (return-from read-object :eof))
    (handler-case
        (with-input-from-string (in (%binary-pending s))
          (let* ((eof (list :eof))
                 (obj (read in nil eof)))
            (cond
              ((eq obj eof)
               (unless (%binary-refill s)
                 (return-from read-object :eof)))
              (t
               (setf (%binary-pending s)
                     (subseq (%binary-pending s) (file-position in)))
               (return-from read-object obj)))))
      (end-of-file ()
        (unless (%binary-refill s)
          (error 'io-read-error :message "incomplete object at end of stream")))
      (reader-error (e)
        (error 'io-read-error :message (princ-to-string e))))))

;;; Factories

(defun make-object-output-stream (underlying &key (element-type 'character))
  "Wrap UNDERLYING as an object-output-stream.
ELEMENT-TYPE is CHARACTER (default) or (UNSIGNED-BYTE 8)."
  (cond
    ((subtypep element-type 'character)
     (make-instance 'character-object-output-stream :underlying underlying))
    ((equal element-type '(unsigned-byte 8))
     (make-instance 'binary-object-output-stream :underlying underlying))
    (t
     (error 'io-error
            :message (format nil "unsupported element-type ~S" element-type)))))

(defun make-object-input-stream (underlying &key (element-type 'character))
  "Wrap UNDERLYING as an object-input-stream."
  (cond
    ((subtypep element-type 'character)
     (make-instance 'character-object-input-stream :underlying underlying))
    ((equal element-type '(unsigned-byte 8))
     (make-instance 'binary-object-input-stream :underlying underlying))
    (t
     (error 'io-error
            :message (format nil "unsupported element-type ~S" element-type)))))
