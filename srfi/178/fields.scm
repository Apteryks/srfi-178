(define (bitvector-field-any? bvec start end)
  (let lp ((i start))
    (and (< i end)
         (or (bitvector-ref/bool bvec i)
             (lp (+ i 1))))))

(define (bitvector-field-every? bvec start end)
  (let lp ((i start))
    (or (>= i end)
        (and (bitvector-ref/bool bvec i)
             (lp (+ i 1))))))

(define (%bitvector-field-modify bvec bit start end)
  (%bitvector-tabulate/int
   (bitvector-length bvec)
   (lambda (i)
     (if (and (>= i start) (< i end))
         bit
         (bitvector-ref/int bvec i)))))

(define (bitvector-field-clear bvec start end)
  (%bitvector-field-modify bvec 0 start end))

(define (bitvector-field-clear! bvec start end)
  (bitvector-fill! bvec 0 start end))

(define (bitvector-field-set bvec start end)
  (%bitvector-field-modify bvec 1 start end))

(define (bitvector-field-set! bvec start end)
  (bitvector-fill! bvec 1 start end))

(define (bitvector-field-replace dest source start end)
  (%bitvector-tabulate/int
   (bitvector-length dest)
   (lambda (i)
     (if (and (>= i start) (< i end))
         (bitvector-ref/int source (- i start))
         (bitvector-ref/int dest i)))))

(define (bitvector-field-replace! dest source start end)
  (bitvector-copy! dest start source 0 (- end start)))

(define (bitvector-field-replace-same dest source start end)
  (%bitvector-tabulate/int
   (bitvector-length dest)
   (lambda (i)
     (bitvector-ref/int (if (and (>= i start) (< i end))
                            source
                            dest)
                        i))))

(define (bitvector-field-replace-same! dest source start end)
  (bitvector-copy! dest start source start end))

(define (bitvector-field-rotate bvec count start end)
  (if (zero? count)
      bvec
      (let ((field-len (- end start)))
        (%bitvector-tabulate/int
         (bitvector-length bvec)
         (lambda (i)
           (if (and (>= i start) (< i end))
               (bitvector-ref/int
                bvec
                (+ start (floor-remainder (+ (- i start) count) field-len)))
               (bitvector-ref/int bvec i)))))))

(define (bitvector-field-reverse bvec start end)
  (%bitvector-tabulate/int
   (bitvector-length bvec)
   (lambda (i)
     (bitvector-ref/int bvec
                        (if (and (>= i start) (< i end))
                            (- end (+ 1 (- i start)))
                            i)))))

(define (bitvector-field-reverse! bvec start end)
  (let ((u8vec (U bvec))
        (pivot (+ start (floor-quotient (- end start) 2))))
    (display pivot)
    (newline)
    (let lp ((i start) (j (- end 1)))
      (unless (>= i pivot)
        (u8vector-swap! u8vec i j)
        (lp (+ i 1) (- j 1))))))

(define (bitvector-field-flip bvec start end)
  (%bitvector-tabulate/int
   (bitvector-length bvec)
   (lambda (i)
     (I (if (and (>= i start) (< i end))
            (not (bitvector-ref/bool bvec i))
            (bitvector-ref/bool bvec i))))))

(define (bitvector-field-flip! bvec start end)
  (let lp ((i start))
    (unless (>= i end)
      (bitvector-set! bvec i (not (bitvector-ref/bool bvec i)))
      (lp (+ i 1)))))
