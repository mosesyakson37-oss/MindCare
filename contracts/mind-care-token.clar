;; MindCare Token Contract
;; Mental Health Access Pass - A token system for counseling session management
;; Implements SIP-010 Fungible Token Standard

;; Constants
(define-constant contract-owner tx-sender)
(define-constant token-name "MindCare Access Pass")
(define-constant token-symbol "MCAP")
(define-constant token-decimals u6)

;; Error constants
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-insufficient-balance (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-unauthorized (err u104))
(define-constant err-provider-not-found (err u105))
(define-constant err-session-not-found (err u106))
(define-constant err-session-already-completed (err u107))
(define-constant err-invalid-session (err u108))

;; Data Variables
(define-data-var total-supply uint u0)
(define-data-var next-session-id uint u1)

;; Data Maps
(define-map token-balances principal uint)
(define-map allowed-operators {owner: principal, operator: principal} uint)

;; Session tracking
(define-map sessions uint {
  client: principal,
  provider: (optional principal),
  amount: uint,
  timestamp: uint,
  completed: bool,
  session-type: (string-ascii 50)
})

(define-map user-sessions principal (list 100 uint))
(define-map provider-sessions principal (list 100 uint))

;; Administrative permissions
(define-map admins principal bool)

;; Initialize contract owner as admin
(map-set admins contract-owner true)

;; SIP-010 Trait Implementation

;; Get token name
(define-read-only (get-name)
  (ok token-name)
)

;; Get token symbol
(define-read-only (get-symbol)
  (ok token-symbol)
)

;; Get token decimals
(define-read-only (get-decimals)
  (ok token-decimals)
)

;; Get token balance of principal
(define-read-only (get-balance (who principal))
  (ok (default-to u0 (map-get? token-balances who)))
)

;; Get total token supply
(define-read-only (get-total-supply)
  (ok (var-get total-supply))
)

;; Get token URI (optional)
(define-read-only (get-token-uri)
  (ok none)
)

;; Private helper functions

;; Check if principal is admin
(define-private (is-admin (principal principal))
  (default-to false (map-get? admins principal))
)

;; Update token balance
(define-private (set-balance (who principal) (new-balance uint))
  (map-set token-balances who new-balance)
)

;; Add session to user's session list
(define-private (add-user-session (user principal) (session-id uint))
  (let (
    (current-sessions (default-to (list) (map-get? user-sessions user)))
  )
    (map-set user-sessions user (unwrap! (as-max-len? (append current-sessions session-id) u100) false))
  )
)

;; Add session to provider's session list
(define-private (add-provider-session (provider principal) (session-id uint))
  (let (
    (current-sessions (default-to (list) (map-get? provider-sessions provider)))
  )
    (map-set provider-sessions provider (unwrap! (as-max-len? (append current-sessions session-id) u100) false))
  )
)

;; Public functions

;; Transfer tokens between principals
(define-public (transfer (amount uint) (from principal) (to principal) (memo (optional (buff 34))))
  (begin
    ;; Ensure sender is authorized
    (asserts! (or (is-eq from tx-sender) (is-eq contract-owner tx-sender)) err-unauthorized)
    
    ;; Validate amount
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Check sender balance
    (let (
      (from-balance (unwrap! (get-balance from) err-insufficient-balance))
      (to-balance (unwrap! (get-balance to) err-insufficient-balance))
    )
      (asserts! (>= from-balance amount) err-insufficient-balance)
      
      ;; Update balances
      (set-balance from (- from-balance amount))
      (set-balance to (+ to-balance amount))
      
      (print {action: "transfer", from: from, to: to, amount: amount, memo: memo})
      (ok true)
    )
  )
)

;; Mint new tokens (admin only)
(define-public (mint (amount uint) (to principal))
  (begin
    ;; Check admin permission
    (asserts! (is-admin tx-sender) err-owner-only)
    
    ;; Validate amount
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Update balance and total supply
    (let (
      (to-balance (unwrap! (get-balance to) err-insufficient-balance))
    )
      (set-balance to (+ to-balance amount))
      (var-set total-supply (+ (var-get total-supply) amount))
      
      (print {action: "mint", to: to, amount: amount})
      (ok true)
    )
  )
)

;; Burn tokens
(define-public (burn (amount uint) (from principal))
  (begin
    ;; Ensure sender is authorized
    (asserts! (or (is-eq from tx-sender) (is-admin tx-sender)) err-unauthorized)
    
    ;; Validate amount
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Check balance
    (let (
      (from-balance (unwrap! (get-balance from) err-insufficient-balance))
    )
      (asserts! (>= from-balance amount) err-insufficient-balance)
      
      ;; Update balance and total supply
      (set-balance from (- from-balance amount))
      (var-set total-supply (- (var-get total-supply) amount))
      
      (print {action: "burn", from: from, amount: amount})
      (ok true)
    )
  )
)

;; Create a counseling session
(define-public (create-session (provider (optional principal)) (amount uint) (session-type (string-ascii 50)))
  (begin
    ;; Validate amount
    (asserts! (> amount u0) err-invalid-amount)
    
    ;; Check user balance
    (let (
      (user-balance (unwrap! (get-balance tx-sender) err-insufficient-balance))
      (session-id (var-get next-session-id))
    )
      (asserts! (>= user-balance amount) err-insufficient-balance)
      
      ;; Create session record
      (map-set sessions session-id {
        client: tx-sender,
        provider: provider,
        amount: amount,
        timestamp: stacks-block-height,
        completed: false,
        session-type: session-type
      })
      
      ;; Add to user sessions
      (add-user-session tx-sender session-id)
      
      ;; Add to provider sessions if provider specified
      (if (is-some provider)
        (add-provider-session (unwrap-panic provider) session-id)
        true
      )
      
      ;; Lock tokens (transfer to contract)
      (set-balance tx-sender (- user-balance amount))
      
      ;; Increment session counter
      (var-set next-session-id (+ session-id u1))
      
      (print {action: "session-created", session-id: session-id, client: tx-sender, provider: provider, amount: amount})
      (ok session-id)
    )
  )
)

;; Complete a session and transfer tokens to provider
(define-public (complete-session (session-id uint))
  (let (
    (session-data (unwrap! (map-get? sessions session-id) err-session-not-found))
  )
    ;; Check if session exists and is valid
    (asserts! (is-eq (get client session-data) tx-sender) err-unauthorized)
    (asserts! (not (get completed session-data)) err-session-already-completed)
    
    ;; Mark session as completed
    (map-set sessions session-id (merge session-data {completed: true}))
    
    ;; Transfer tokens to provider if specified
    (if (is-some (get provider session-data))
      (let (
        (provider-principal (unwrap-panic (get provider session-data)))
        (provider-balance (unwrap! (get-balance provider-principal) err-insufficient-balance))
      )
        (begin
          (set-balance provider-principal (+ provider-balance (get amount session-data)))
          (print {action: "session-completed", session-id: session-id, provider: provider-principal})
          true
        )
      )
      ;; Return tokens to client if no provider
      (let (
        (client-balance (unwrap! (get-balance (get client session-data)) err-insufficient-balance))
      )
        (begin
          (set-balance (get client session-data) (+ client-balance (get amount session-data)))
          (print {action: "session-cancelled", session-id: session-id})
          true
        )
      )
    )
    
    (ok true)
  )
)

;; Provider redeems tokens for completed session
(define-public (redeem-session (session-id uint))
  (let (
    (session-data (unwrap! (map-get? sessions session-id) err-session-not-found))
  )
    ;; Verify provider authorization
    (asserts! (is-some (get provider session-data)) err-provider-not-found)
    (asserts! (is-eq (some tx-sender) (get provider session-data)) err-unauthorized)
    (asserts! (not (get completed session-data)) err-session-already-completed)
    
    ;; Mark session as completed
    (map-set sessions session-id (merge session-data {completed: true}))
    
    ;; Transfer tokens to provider
    (let (
      (provider-balance (unwrap! (get-balance tx-sender) err-insufficient-balance))
    )
      (set-balance tx-sender (+ provider-balance (get amount session-data)))
      
      (print {action: "session-redeemed", session-id: session-id, provider: tx-sender, amount: (get amount session-data)})
      (ok true)
    )
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

;; Get session details
(define-read-only (get-session (session-id uint))
  (map-get? sessions session-id)
)

;; Get user sessions
(define-read-only (get-user-sessions (user principal))
  (default-to (list) (map-get? user-sessions user))
)

;; Get provider sessions
(define-read-only (get-provider-sessions (provider principal))
  (default-to (list) (map-get? provider-sessions provider))
)

;; Check if principal is admin
(define-read-only (is-admin-check (principal principal))
  (is-admin principal)
)

;; Get contract info
(define-read-only (get-contract-info)
  {
    name: token-name,
    symbol: token-symbol,
    decimals: token-decimals,
    total-supply: (var-get total-supply),
    owner: contract-owner,
    next-session-id: (var-get next-session-id)
  }
)


