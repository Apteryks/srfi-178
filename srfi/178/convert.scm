;;;; Bit conversions

(define (bit->integer bit) (I bit))

(define (bit->boolean bit) (B bit))

(define (bitvector->string bvec)
  (let loop ((i (- (bitvector-length bvec) 1))
             (r '()))
    (if (< i 0)
      (list->string (cons #\# (cons #\* r)))
      (loop (cons (if (bitvector-ref/bool bvec i) #\1 #\0) r) (- i 1)))))

(define (string->bitvector str)
  (call/cc
   (lambda (return)
     (and
       (char=? (string-ref str 0) #\#)
       (char=? (string-ref str 1) #\*)
       (bitvector-unfold/int
        (lambda (ri si)
          (case (string-ref str si)
            ((#\0) (values 0 (+ si 1)))
            ((#\1) (values 1 (+ si 1)))
            (else (return #f))))
        (- (string-length str) 2)
        2)))))

(define (bitvector->integer bvec)
  (let ((len (bitvector-length bvec)))
    (let lp ((r 0) (i 0))
      (if (= i len)
          r
          (lp (bitwise-ior
               r
               (arithmetic-shift (bitvector-ref/int bvec i) i))
              (+ i 1))))))

(define (integer->bitvector int)
  (bitvector-unfold/bool
   (lambda (_ int)
     (values (bit-set? 0 int) (arithmetic-shift int -1)))
   (integer-length int)
   int))

(define (bitvector->bytevector* bytevec start end)
  #f)

(define bytevector->bitvector
  (case-lambda
    ((bytevec)
     (bytevector->bitvector* bytevec
                             0
                             (* 8 (bytevector-length bytevec))))
    ((bytevec start)
     (bytevector->bitvector* bytevec
                             start
                             (* 8 (bytevector-length bytevec))))
    ((bytevec start end)
     (bytevector->bitvector* bytevec start end))))

;; Write the bits of byte into the bitvector to.  Big-endian.
(define %bitvector-copy-byte!
  (case-lambda
    ((to at byte) (%bitvector-copy-byte! to at byte 0 8))
    ((to at byte start) (%bitvector-copy-byte! to at byte start 8))
    ((to at byte start end)
     (let lp ((i at) (j (- end 1)))
       (unless (< j start)
         (bitvector-set! to i (bit-set? j byte))
         (lp (+ i 1) (- j 1)))))))

;; Write the bits of the selected range of the bytevector from into
;; the bitvector to.  start and end are bytevector indices.
(define (%bitvector-copy-bytevector! to at from start end)
  (let lp ((i at) (j start))
    (unless (>= j end)
      (%bitvector-copy-byte! to i (bytevector-u8-ref from j))
      (lp (+ i 8) (+ j 1)))))

;; FIXME: Edge cases.
(define (bytevector->bitvector* bytevec start end)
  (let-values (((start-byte start-off) (floor/ start 8))
               ((end-byte end-seg) (floor/ end 8))
               ((ri) 0))
    (let* ((length (- end start))
           (result (make-bitvector length)))
      ;; Copy leading bits.
      (%bitvector-copy-byte! result
                             0
                             (bytevector-u8-ref bytevec start-byte)
                             start-off)
      (set! ri (+ ri (- 8 start-off)))
      ;; Copy all whole bytes.
      (%bitvector-copy-bytevector! result
                                   ri
                                   bytevec
                                   (+ start-byte 1)
                                   end-byte)
      ;; Copy trailing bits.
      (%bitvector-copy-byte! result
                             (+ ri (* 8 (- end-byte start-byte)))
                             (bytevector-u8-ref bytevec end-byte)
                             0
                             end-seg)
      result)))

(define bitvector->bytevector
  (case-lambda
    ((bvec)
     (bitvector->bytevector* bvec 0 (bitvector-length bvec)))
    ((bvec start)
     (bitvector->bytevector* bvec start (bitvector-length bvec)))
    ((bvec start end)
     (bitvector->bytevector* bvec start end))))

(define (bitvector->bytevector!* bvec start end)
  #f)

(define bitvector->bytevector!
  (case-lambda
    ((bvec)
     (bitvector->bytevector!* bvec 0 (bitvector-length bvec)))
    ((bvec start)
     (bitvector->bytevector!* bvec start (bitvector-length bvec)))
    ((bvec start end)
     (bitvector->bytevector!* bvec start end))))
