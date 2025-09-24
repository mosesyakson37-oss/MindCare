;; Provider Registry Contract
;; Mental Health Provider Registration and Management System
;; Manages verification, credentials, and service tracking for mental health professionals

;; Constants
(define-constant contract-owner tx-sender)
(define-constant max-providers u1000)
(define-constant max-specialties u10)
(define-constant max-reviews u50)

;; Error constants
(define-constant err-owner-only (err u200))
(define-constant err-unauthorized (err u201))
(define-constant err-provider-exists (err u202))
(define-constant err-provider-not-found (err u203))
(define-constant err-invalid-data (err u204))
(define-constant err-not-verified (err u205))
(define-constant err-invalid-rating (err u206))
(define-constant err-review-exists (err u207))
(define-constant err-self-review (err u208))
(define-constant err-max-specialties (err u209))

;; Data Variables
(define-data-var total-providers uint u0)
(define-data-var next-provider-id uint u1)

;; Provider profile structure
(define-map providers principal {
  id: uint,
  name: (string-ascii 100),
  credentials: (string-ascii 200),
  specialties: (list 10 (string-ascii 50)),
  verified: bool,
  license-number: (string-ascii 50),
  registration-date: uint,
  total-sessions: uint,
  average-rating: uint,
  review-count: uint,
  active: bool
})

;; Provider ID mapping
(define-map provider-ids uint principal)

;; Administrative permissions
(define-map admins principal bool)

;; Service reviews and ratings
(define-map reviews {provider: principal, reviewer: principal} {
  rating: uint,
  comment: (string-ascii 500),
  timestamp: uint,
  session-id: (optional uint)
})

;; Provider session statistics
(define-map session-stats principal {
  completed-sessions: uint,
  total-earnings: uint,
  last-session: uint,
  cancellation-rate: uint
})

;; Specialty tracking
(define-map specialty-providers (string-ascii 50) (list 100 principal))

;; Initialize contract owner as admin
(map-set admins contract-owner true)

;; Private helper functions

;; Check if principal is admin
(define-private (is-admin (principal principal))
  (default-to false (map-get? admins principal))
)

;; Validate rating value (1-5 scale)
(define-private (is-valid-rating (rating uint))
  (and (>= rating u1) (<= rating u5))
)

;; Add provider to specialty list
(define-private (add-to-specialty (specialty (string-ascii 50)) (provider principal))
  (let (
    (current-providers (default-to (list) (map-get? specialty-providers specialty)))
  )
    (if (is-none (index-of current-providers provider))
      (map-set specialty-providers specialty 
        (unwrap! (as-max-len? (append current-providers provider) u100) false)
      )
      true
    )
  )
)

;; Update provider's average rating
(define-private (update-provider-rating (provider principal) (new-rating uint))
  (let (
    (provider-data (unwrap! (map-get? providers provider) false))
    (current-avg (get average-rating provider-data))
    (review-count (get review-count provider-data))
    (new-count (+ review-count u1))
    (new-avg (/ (+ (* current-avg review-count) new-rating) new-count))
  )
    (map-set providers provider
      (merge provider-data {
        average-rating: new-avg,
        review-count: new-count
      })
    )
  )
)

;; Public functions

;; Register as a mental health provider
(define-public (register-provider 
    (name (string-ascii 100)) 
    (credentials (string-ascii 200))
    (license-number (string-ascii 50))
    (specialties (list 10 (string-ascii 50)))
  )
  (begin
    ;; Check if provider already exists
    (asserts! (is-none (map-get? providers tx-sender)) err-provider-exists)
    
    ;; Validate input data
    (asserts! (> (len name) u0) err-invalid-data)
    (asserts! (> (len credentials) u0) err-invalid-data)
    (asserts! (> (len license-number) u0) err-invalid-data)
    (asserts! (<= (len specialties) max-specialties) err-max-specialties)
    
    ;; Create provider profile
    (let (
      (provider-id (var-get next-provider-id))
    )
      (map-set providers tx-sender {
        id: provider-id,
        name: name,
        credentials: credentials,
        specialties: specialties,
        verified: false,
        license-number: license-number,
        registration-date: stacks-block-height,
        total-sessions: u0,
        average-rating: u0,
        review-count: u0,
        active: true
      })
      
      ;; Map provider ID to principal
      (map-set provider-ids provider-id tx-sender)
      
      ;; Initialize session stats
      (map-set session-stats tx-sender {
        completed-sessions: u0,
        total-earnings: u0,
        last-session: u0,
        cancellation-rate: u0
      })
      
      ;; Add to specialty lists
      (map add-to-specialty specialties (list tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender))
      
      ;; Update counters
      (var-set total-providers (+ (var-get total-providers) u1))
      (var-set next-provider-id (+ provider-id u1))
      
      (print {action: "provider-registered", provider: tx-sender, id: provider-id, name: name})
      (ok provider-id)
    )
  )
)

;; Update provider profile
(define-public (update-provider-profile 
    (name (string-ascii 100))
    (credentials (string-ascii 200))
    (specialties (list 10 (string-ascii 50)))
  )
  (let (
    (provider-data (unwrap! (map-get? providers tx-sender) err-provider-not-found))
  )
    ;; Validate input data
    (asserts! (> (len name) u0) err-invalid-data)
    (asserts! (> (len credentials) u0) err-invalid-data)
    (asserts! (<= (len specialties) max-specialties) err-max-specialties)
    
    ;; Update provider profile
    (map-set providers tx-sender
      (merge provider-data {
        name: name,
        credentials: credentials,
        specialties: specialties
      })
    )
    
    ;; Update specialty lists (simplified - would need more complex logic for removals)
    (map add-to-specialty specialties (list tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender tx-sender))
    
    (print {action: "profile-updated", provider: tx-sender})
    (ok true)
  )
)

;; Verify provider (admin only)
(define-public (verify-provider (provider principal))
  (let (
    (provider-data (unwrap! (map-get? providers provider) err-provider-not-found))
  )
    ;; Check admin permission
    (asserts! (is-admin tx-sender) err-owner-only)
    
    ;; Update verification status
    (map-set providers provider
      (merge provider-data {verified: true})
    )
    
    (print {action: "provider-verified", provider: provider, admin: tx-sender})
    (ok true)
  )
)

;; Revoke provider verification (admin only)
(define-public (revoke-verification (provider principal))
  (let (
    (provider-data (unwrap! (map-get? providers provider) err-provider-not-found))
  )
    ;; Check admin permission
    (asserts! (is-admin tx-sender) err-owner-only)
    
    ;; Update verification status
    (map-set providers provider
      (merge provider-data {verified: false})
    )
    
    (print {action: "verification-revoked", provider: provider, admin: tx-sender})
    (ok true)
  )
)

;; Deactivate provider (admin only or self)
(define-public (deactivate-provider (provider principal))
  (let (
    (provider-data (unwrap! (map-get? providers provider) err-provider-not-found))
  )
    ;; Check authorization
    (asserts! (or (is-admin tx-sender) (is-eq tx-sender provider)) err-unauthorized)
    
    ;; Update active status
    (map-set providers provider
      (merge provider-data {active: false})
    )
    
    (print {action: "provider-deactivated", provider: provider})
    (ok true)
  )
)

;; Reactivate provider (admin only or self)
(define-public (reactivate-provider (provider principal))
  (let (
    (provider-data (unwrap! (map-get? providers provider) err-provider-not-found))
  )
    ;; Check authorization
    (asserts! (or (is-admin tx-sender) (is-eq tx-sender provider)) err-unauthorized)
    
    ;; Update active status
    (map-set providers provider
      (merge provider-data {active: true})
    )
    
    (print {action: "provider-reactivated", provider: provider})
    (ok true)
  )
)

;; Submit provider review
(define-public (submit-review 
    (provider principal)
    (rating uint)
    (comment (string-ascii 500))
    (session-id (optional uint))
  )
  (begin
    ;; Validate inputs
    (asserts! (is-valid-rating rating) err-invalid-rating)
    (asserts! (not (is-eq tx-sender provider)) err-self-review)
    
    ;; Check if provider exists and is active
    (let (
      (provider-data (unwrap! (map-get? providers provider) err-provider-not-found))
    )
      (asserts! (get active provider-data) err-provider-not-found)
      
      ;; Check if review already exists
      (asserts! (is-none (map-get? reviews {provider: provider, reviewer: tx-sender})) err-review-exists)
      
      ;; Create review
      (map-set reviews {provider: provider, reviewer: tx-sender} {
        rating: rating,
        comment: comment,
        timestamp: stacks-block-height,
        session-id: session-id
      })
      
      ;; Update provider's average rating
      (update-provider-rating provider rating)
      
      (print {action: "review-submitted", provider: provider, reviewer: tx-sender, rating: rating})
      (ok true)
    )
  )
)

;; Record session completion (called by token contract)
(define-public (record-session-completion (provider principal) (earnings uint))
  (let (
    (provider-data (unwrap! (map-get? providers provider) err-provider-not-found))
    (stats (default-to {completed-sessions: u0, total-earnings: u0, last-session: u0, cancellation-rate: u0} 
                       (map-get? session-stats provider)))
  )
    ;; Update provider session count
    (map-set providers provider
      (merge provider-data {
        total-sessions: (+ (get total-sessions provider-data) u1)
      })
    )
    
    ;; Update session statistics
    (map-set session-stats provider
      (merge stats {
        completed-sessions: (+ (get completed-sessions stats) u1),
        total-earnings: (+ (get total-earnings stats) earnings),
        last-session: stacks-block-height
      })
    )
    
    (print {action: "session-completed", provider: provider, earnings: earnings})
    (ok true)
  )
)

;; Administrative functions

;; Add admin (owner only)
(define-public (add-admin (new-admin principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set admins new-admin true)
    (print {action: "admin-added", admin: new-admin})
    (ok true)
  )
)

;; Remove admin (owner only)
(define-public (remove-admin (admin principal))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-delete admins admin)
    (print {action: "admin-removed", admin: admin})
    (ok true)
  )
)

;; Read-only functions

;; Get provider profile
(define-read-only (get-provider (provider principal))
  (map-get? providers provider)
)

;; Get provider by ID
(define-read-only (get-provider-by-id (provider-id uint))
  (match (map-get? provider-ids provider-id)
    provider-principal (map-get? providers provider-principal)
    none
  )
)

;; Get provider session statistics
(define-read-only (get-provider-stats (provider principal))
  (map-get? session-stats provider)
)

;; Get providers by specialty
(define-read-only (get-providers-by-specialty (specialty (string-ascii 50)))
  (default-to (list) (map-get? specialty-providers specialty))
)

;; Get review
(define-read-only (get-review (provider principal) (reviewer principal))
  (map-get? reviews {provider: provider, reviewer: reviewer})
)

;; Check if provider is verified
(define-read-only (is-provider-verified (provider principal))
  (match (map-get? providers provider)
    provider-data (get verified provider-data)
    false
  )
)

;; Check if provider is active
(define-read-only (is-provider-active (provider principal))
  (match (map-get? providers provider)
    provider-data (get active provider-data)
    false
  )
)

;; Check if principal is admin
(define-read-only (is-admin-check (principal principal))
  (is-admin principal)
)

;; Get contract statistics
(define-read-only (get-contract-stats)
  {
    total-providers: (var-get total-providers),
    next-provider-id: (var-get next-provider-id),
    contract-owner: contract-owner
  }
)

