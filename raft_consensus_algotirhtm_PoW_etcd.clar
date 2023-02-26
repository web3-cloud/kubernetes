# Sample Etcd changes to used PoW to join the cluster cluster-join

(define-data-var nodes (list string))
(define-data-var current-term uint)
(define-data-var voted-for (optional string))
(define-data-var log (list any))
(define-data-var commit-index uint)
(define-data-var last-applied uint)
(define-data-var state uint)
(define-data-var nonce uint)
(define-data-var difficulty uint)

(define (request-vote term candidate-id last-log-index last-log-term nonce)
  (let ((valid (and (>= term current-term)
                    (or (eq? voted-for candidate-id) (null? voted-for))
                    (>= last-log-index commit-index)
                    (or (> last-log-term (log-term-at-index log last-log-index))
                        (and (= last-log-term (log-term-at-index log last-log-index))
                             (>= last-log-index (length log) (- (length log) commit-index))))
                    (check-pow nonce difficulty))))
    (when valid
      (set-voted-for candidate-id)
      (set-current-term term))
    valid))

(define (append-entries term leader-id prev-log-index prev-log-term entries leader-commit nonce)
  (let ((valid (and (>= term current-term)
                    (= (nth nodes leader-id) leader-id)
                    (>= prev-log-index commit-index)
                    (or (<= prev-log-index (- (length log) 1))
                        (eq? (log-term-at-index log prev-log-index) prev-log-term))
                    (check-pow nonce difficulty))))
    (when valid
      (let ((index (1+ prev-log-index))
            (pos (- index commit-index)))
        (when (> index (+ (length log) 1))
          (set-log (append log (make-list (- index (length log)) null))))
        (set-car! (cdr (drop log pos)) entries)
        (set-commit-index (min leader-commit (+ index (length entries) -1)))))
    valid))

(define (check-pow nonce difficulty)
  (<= (sha256 (list nonce current-term voted-for log commit-index last-applied state)) difficulty))

(define (mine-pow)
  (let ((nonce 0))
    (while (not (check-pow nonce difficulty))
      (set-nonce (add nonce 1)))
    nonce))

(define (join-cluster)
  (let ((nonce (mine-pow)))
    (let ((nodes (get-nodes-from-seed-node seed-node-url)))
      (let ((last-log-index (- (length log) 1))
            (last-log-term (log-term-at-index log (- (length log) 1))))
        (broadcast-election-request current-term current-node-id last-log-index last-log-term nonce)))))


