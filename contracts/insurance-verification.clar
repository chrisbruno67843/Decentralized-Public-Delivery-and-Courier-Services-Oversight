;; Insurance and Liability Verification Contract
;; Ensures delivery services maintain proper insurance coverage

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-NOT-AUTHORIZED (err u500))
(define-constant ERR-POLICY-NOT-FOUND (err u501))
(define-constant ERR-INVALID-INPUT (err u502))
(define-constant ERR-POLICY-EXPIRED (err u503))
(define-constant ERR-INSUFFICIENT-COVERAGE (err u504))
(define-constant ERR-CLAIM-NOT-FOUND (err u505))

;; Data Variables
(define-data-var minimum-liability-coverage uint u1000000) ;; $1M in micro-STX
(define-data-var minimum-cargo-coverage uint u500000) ;; $500K in micro-STX
(define-data-var verification-fee uint u100)
(define-data-var claim-counter uint u0)

;; Data Maps
(define-map insurance-policies
  { courier: principal }
  {
    policy-number: (string-ascii 100),
    insurer: (string-ascii 100),
    policy-type: (string-ascii 50),
    liability-coverage: uint,
    cargo-coverage: uint,
    issue-date: uint,
    expiry-date: uint,
    status: (string-ascii 20),
    premium-paid: bool,
    verification-date: uint
  }
)

(define-map insurance-claims
  { claim-id: uint }
  {
    claimant: principal,
    courier: principal,
    claim-type: (string-ascii 50),
    claim-amount: uint,
    incident-date: uint,
    claim-date: uint,
    status: (string-ascii 20),
    description: (string-ascii 500),
    settlement-amount: uint
  }
)

(define-map coverage-requirements
  { service-type: (string-ascii 50) }
  {
    min-liability: uint,
    min-cargo: uint,
    additional-requirements: (string-ascii 200)
  }
)

(define-map courier-claims-history
  { courier: principal }
  {
    total-claims: uint,
    total-payouts: uint,
    claims-ratio: uint,
    risk-score: uint
  }
)

;; Private Functions
(define-private (is-policy-valid (courier principal))
  (match (map-get? insurance-policies { courier: courier })
    policy-data (and
      (is-eq (get status policy-data) "active")
      (> (get expiry-date policy-data) block-height)
      (get premium-paid policy-data)
    )
    false
  )
)

(define-private (meets-coverage-requirements (courier principal) (service-type (string-ascii 50)))
  (match (map-get? insurance-policies { courier: courier })
    policy-data
      (match (map-get? coverage-requirements { service-type: service-type })
        requirements (and
          (>= (get liability-coverage policy-data) (get min-liability requirements))
          (>= (get cargo-coverage policy-data) (get min-cargo requirements))
        )
        ;; Default requirements if service type not found
        (and
          (>= (get liability-coverage policy-data) (var-get minimum-liability-coverage))
          (>= (get cargo-coverage policy-data) (var-get minimum-cargo-coverage))
        )
      )
    false
  )
)

(define-private (get-next-claim-id)
  (let ((current-id (var-get claim-counter)))
    (begin
      (var-set claim-counter (+ current-id u1))
      (+ current-id u1)
    )
  )
)

;; Public Functions
(define-public (register-insurance-policy
  (policy-number (string-ascii 100))
  (insurer (string-ascii 100))
  (policy-type (string-ascii 50))
  (liability-coverage uint)
  (cargo-coverage uint)
  (expiry-date uint)
)
  (begin
    (asserts! (> (len policy-number) u0) ERR-INVALID-INPUT)
    (asserts! (> (len insurer) u0) ERR-INVALID-INPUT)
    (asserts! (> expiry-date block-height) ERR-INVALID-INPUT)
    (asserts! (>= liability-coverage (var-get minimum-liability-coverage)) ERR-INSUFFICIENT-COVERAGE)
    (asserts! (>= cargo-coverage (var-get minimum-cargo-coverage)) ERR-INSUFFICIENT-COVERAGE)

    (ok (map-set insurance-policies
      { courier: tx-sender }
      {
        policy-number: policy-number,
        insurer: insurer,
        policy-type: policy-type,
        liability-coverage: liability-coverage,
        cargo-coverage: cargo-coverage,
        issue-date: block-height,
        expiry-date: expiry-date,
        status: "pending",
        premium-paid: false,
        verification-date: u0
      }
    ))
  )
)

(define-public (verify-policy (courier principal) (payment uint))
  (let (
    (policy-data (unwrap! (map-get? insurance-policies { courier: courier }) ERR-POLICY-NOT-FOUND))
    (verification-cost (var-get verification-fee))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (>= payment verification-cost) ERR-INVALID-INPUT)

    (try! (stx-transfer? payment tx-sender CONTRACT-OWNER))

    (ok (map-set insurance-policies
      { courier: courier }
      (merge policy-data {
        status: "verified",
        verification-date: block-height
      })
    ))
  )
)

(define-public (confirm-premium-payment (courier principal))
  (let ((policy-data (unwrap! (map-get? insurance-policies { courier: courier }) ERR-POLICY-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)

    (ok (map-set insurance-policies
      { courier: courier }
      (merge policy-data {
        premium-paid: true,
        status: (if (is-eq (get status policy-data) "verified") "active" (get status policy-data))
      })
    ))
  )
)

(define-public (file-insurance-claim
  (courier principal)
  (claim-type (string-ascii 50))
  (claim-amount uint)
  (incident-date uint)
  (description (string-ascii 500))
)
  (let ((claim-id (get-next-claim-id)))
    (asserts! (is-policy-valid courier) ERR-POLICY-EXPIRED)
    (asserts! (> claim-amount u0) ERR-INVALID-INPUT)
    (asserts! (<= incident-date block-height) ERR-INVALID-INPUT)

    (map-set insurance-claims
      { claim-id: claim-id }
      {
        claimant: tx-sender,
        courier: courier,
        claim-type: claim-type,
        claim-amount: claim-amount,
        incident-date: incident-date,
        claim-date: block-height,
        status: "filed",
        description: description,
        settlement-amount: u0
      }
    )

    ;; Update claims history
    (let ((history (default-to
      { total-claims: u0, total-payouts: u0, claims-ratio: u0, risk-score: u50 }
      (map-get? courier-claims-history { courier: courier })
    )))
      (map-set courier-claims-history
        { courier: courier }
        (merge history {
          total-claims: (+ (get total-claims history) u1)
        })
      )
    )

    (ok claim-id)
  )
)

(define-public (process-claim (claim-id uint) (settlement-amount uint) (new-status (string-ascii 20)))
  (let ((claim-data (unwrap! (map-get? insurance-claims { claim-id: claim-id }) ERR-CLAIM-NOT-FOUND)))
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (<= settlement-amount (get claim-amount claim-data)) ERR-INVALID-INPUT)

    (map-set insurance-claims
      { claim-id: claim-id }
      (merge claim-data {
        status: new-status,
        settlement-amount: settlement-amount
      })
    )

    ;; Update claims history if settled
    (if (is-eq new-status "settled")
      (let ((history (default-to
        { total-claims: u0, total-payouts: u0, claims-ratio: u0, risk-score: u50 }
        (map-get? courier-claims-history { courier: (get courier claim-data) })
      )))
        (map-set courier-claims-history
          { courier: (get courier claim-data) }
          (merge history {
            total-payouts: (+ (get total-payouts history) settlement-amount),
            claims-ratio: (if (> (get total-claims history) u0)
              (/ (* (get total-payouts history) u100) (get total-claims history))
              u0
            )
          })
        )
      )
      true
    )

    (ok true)
  )
)

(define-public (renew-policy (expiry-date uint))
  (let ((policy-data (unwrap! (map-get? insurance-policies { courier: tx-sender }) ERR-POLICY-NOT-FOUND)))
    (asserts! (> expiry-date block-height) ERR-INVALID-INPUT)

    (ok (map-set insurance-policies
      { courier: tx-sender }
      (merge policy-data {
        expiry-date: expiry-date,
        status: "pending",
        premium-paid: false
      })
    ))
  )
)

(define-public (set-coverage-requirements
  (service-type (string-ascii 50))
  (min-liability uint)
  (min-cargo uint)
  (additional-requirements (string-ascii 200))
)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (> min-liability u0) ERR-INVALID-INPUT)
    (asserts! (> min-cargo u0) ERR-INVALID-INPUT)

    (ok (map-set coverage-requirements
      { service-type: service-type }
      {
        min-liability: min-liability,
        min-cargo: min-cargo,
        additional-requirements: additional-requirements
      }
    ))
  )
)

;; Read-only Functions
(define-read-only (get-policy-info (courier principal))
  (map-get? insurance-policies { courier: courier })
)

(define-read-only (is-insured (courier principal))
  (is-policy-valid courier)
)

(define-read-only (check-coverage-compliance (courier principal) (service-type (string-ascii 50)))
  (meets-coverage-requirements courier service-type)
)

(define-read-only (get-claim-info (claim-id uint))
  (map-get? insurance-claims { claim-id: claim-id })
)

(define-read-only (get-claims-history (courier principal))
  (map-get? courier-claims-history { courier: courier })
)

(define-read-only (get-coverage-requirements (service-type (string-ascii 50)))
  (map-get? coverage-requirements { service-type: service-type })
)

(define-read-only (get-minimum-coverage)
  {
    liability: (var-get minimum-liability-coverage),
    cargo: (var-get minimum-cargo-coverage)
  }
)
