;; BlockID - Enhanced Decentralized Identity Management Contract

;; Define error messages
(define-constant ERR-IDENTITY-EXISTS (err "Identity already exists"))
(define-constant ERR-IDENTITY-NOT-FOUND (err "Identity not found"))
(define-constant ERR-INVALID-HANDLE (err "Invalid handle: must be between 3 and 50 characters"))
(define-constant ERR-INVALID-CONTACT (err "Invalid contact: must be between 5 and 100 characters and contain '@' and '.'"))
(define-constant ERR-INVALID-AVATAR (err "Invalid avatar URL: must be a valid URL string"))
(define-constant ERR-INVALID-BIO (err "Invalid bio: must be between 1 and 500 characters"))
(define-constant ERR-UNAUTHORIZED (err "Unauthorized operation"))
(define-constant ERR-INVALID-SOCIAL-LINK (err "Invalid social media link"))
(define-constant ERR-INVALID-VERIFICATION (err "Invalid verification data"))
(define-constant ERR-ALREADY-VERIFIED (err "Identity already verified"))
(define-constant ERR-INVALID-CREDENTIALS (err "Invalid credentials"))
(define-constant ERR-RECOVERY-EXISTS (err "Recovery address already set"))
(define-constant ERR-INVALID-BADGE (err "Invalid badge format"))

;; Define data maps
(define-map identities principal
  {
    handle: (string-ascii 50),
    contact: (string-ascii 100),
    avatar: (optional (string-utf8 256)),
    bio: (optional (string-utf8 500)),
    creation-time: uint,
    last-updated: uint,
    verification-status: bool,
    social-links: (list 5 (string-utf8 256)),
    recovery-address: (optional principal)
  }
)

(define-map identity-credentials principal
  {
    password-hash: (buff 32),
    last-login: uint,
    login-attempts: uint,
    locked-until: uint
  }
)

(define-map identity-metadata principal
  {
    reputation-score: uint,
    trust-level: uint,
    badges: (list 10 (string-ascii 50)),
    following-count: uint,
    followers-count: uint
  }
)

(define-map identity-relationships
  { follower: principal, following: principal }
  { timestamp: uint }
)

;; Define data variables
(define-data-var identity-count uint u0)
(define-data-var admin-address principal tx-sender)
(define-data-var verification-fee uint u1000)
(define-data-var lockout-threshold uint u5)
(define-data-var lockout-period uint u3600) ;; 1 hour in seconds

;; Private functions
(define-private (validate-handle (handle (string-ascii 50)))
  (let
    ((length (len handle)))
    (and (>= length u3) (<= length u50))
  )
)

(define-private (validate-contact (contact (string-ascii 100)))
  (let
    ((length (len contact))
     (has-at (is-some (index-of contact "@")))
     (has-dot (is-some (index-of contact "."))))
    (and (>= length u5) (<= length u100) has-at has-dot)
  )
)

(define-private (validate-bio (bio (string-utf8 500)))
  (let
    ((length (len bio)))
    (and (> length u0) (<= length u500))
  )
)

(define-private (validate-badge (badge (string-ascii 50)))
  (let
    ((length (len badge)))
    (and (> length u0) (<= length u50))
  )
)

(define-private (validate-password-hash (hash (buff 32)))
  (is-eq (len hash) u32)
)

;; Fixed check-login-status function
(define-private (check-login-status (caller principal))
  (let
    ((creds (map-get? identity-credentials caller)))
    (if (is-none creds)
      (err ERR-INVALID-CREDENTIALS)
      (let
        ((unwrapped-creds (unwrap-panic creds))
         (current-time block-height))
        (ok (> (get locked-until unwrapped-creds) current-time))
      )
    )
  )
)

;; Public functions

;; Enhanced registration with additional validation
(define-public (register-identity 
    (handle (string-ascii 50)) 
    (contact (string-ascii 100))
    (bio (optional (string-utf8 500)))
    (password-hash (buff 32)))
  (let
    ((caller tx-sender)
     (safe-handle (as-max-len? handle u50))
     (safe-contact (as-max-len? contact u100)))
    
    ;; Input validation
    (asserts! (is-none (map-get? identities caller)) ERR-IDENTITY-EXISTS)
    (asserts! (is-some safe-handle) ERR-INVALID-HANDLE)
    (asserts! (is-some safe-contact) ERR-INVALID-CONTACT)
    (asserts! (validate-handle (unwrap-panic safe-handle)) ERR-INVALID-HANDLE)
    (asserts! (validate-contact (unwrap-panic safe-contact)) ERR-INVALID-CONTACT)
    (asserts! (validate-password-hash password-hash) ERR-INVALID-CREDENTIALS)
    
    ;; Bio validation if provided
    (asserts! (match bio
      bio-value (validate-bio bio-value)
      true) ERR-INVALID-BIO)
    
    ;; Set identity data
    (map-set identities caller
      {
        handle: (unwrap-panic safe-handle),
        contact: (unwrap-panic safe-contact),
        avatar: none,
        bio: bio,
        creation-time: block-height,
        last-updated: block-height,
        verification-status: false,
        social-links: (list),
        recovery-address: none
      }
    )
    
    ;; Set credentials
    (map-set identity-credentials caller
      {
        password-hash: password-hash,
        last-login: block-height,
        login-attempts: u0,
        locked-until: u0
      }
    )
    
    ;; Initialize metadata
    (map-set identity-metadata caller
      {
        reputation-score: u0,
        trust-level: u0,
        badges: (list),
        following-count: u0,
        followers-count: u0
      }
    )
    
    (var-set identity-count (+ (var-get identity-count) u1))
    (ok true)
  )
)

;; Identity verification
(define-public (verify-identity (verification-data (buff 32)))
  (let
    ((caller tx-sender)
     (identity-data (unwrap! (map-get? identities caller) ERR-IDENTITY-NOT-FOUND)))
    (asserts! (not (get verification-status identity-data)) ERR-ALREADY-VERIFIED)
    ;; Add verification logic here
    (map-set identities caller
      (merge identity-data
        {
          verification-status: true,
          last-updated: block-height
        }
      )
    )
    (ok true)
  )
)

;; Social relationship management
(define-public (follow-identity (to-follow principal))
  (let
    ((caller tx-sender))
    (asserts! (is-some (map-get? identities to-follow)) ERR-IDENTITY-NOT-FOUND)
    (asserts! (not (is-eq caller to-follow)) ERR-INVALID-CREDENTIALS)
    
    (map-set identity-relationships
      { follower: caller, following: to-follow }
      { timestamp: block-height }
    )
    
    ;; Update follower counts
    (map-set identity-metadata to-follow
      (merge (unwrap! (map-get? identity-metadata to-follow) ERR-IDENTITY-NOT-FOUND)
        { followers-count: (+ (get followers-count (unwrap-panic (map-get? identity-metadata to-follow))) u1) }
      )
    )
    
    (map-set identity-metadata caller
      (merge (unwrap! (map-get? identity-metadata caller) ERR-IDENTITY-NOT-FOUND)
        { following-count: (+ (get following-count (unwrap-panic (map-get? identity-metadata caller))) u1) }
      )
    )
    (ok true)
  )
)

;; Recovery address management
(define-public (set-recovery-address (recovery principal))
  (let
    ((caller tx-sender)
     (identity-data (unwrap! (map-get? identities caller) ERR-IDENTITY-NOT-FOUND)))
    (asserts! (is-none (get recovery-address identity-data)) ERR-RECOVERY-EXISTS)
    (map-set identities caller
      (merge identity-data
        {
          recovery-address: (some recovery),
          last-updated: block-height
        }
      )
    )
    (ok true)
  )
)

;; Enhanced badge management with validation
(define-public (award-badge (to principal) (badge (string-ascii 50)))
  (let
    ((caller tx-sender)
     (target-metadata (unwrap! (map-get? identity-metadata to) ERR-IDENTITY-NOT-FOUND)))
    
    ;; Validate inputs
    (asserts! (is-eq caller (var-get admin-address)) ERR-UNAUTHORIZED)
    (asserts! (validate-badge badge) ERR-INVALID-BADGE)
    (asserts! (is-some (map-get? identities to)) ERR-IDENTITY-NOT-FOUND)
    
    ;; Update badges
    (ok (map-set identity-metadata to
      (merge target-metadata
        {
          badges: (unwrap-panic (as-max-len? 
            (append (get badges target-metadata) badge)
            u10))
        }
      )))
  )
)

;; Read-only functions

(define-read-only (get-identity-info (identity principal))
  (map-get? identities identity)
)

(define-read-only (get-identity-metadata (identity principal))
  (map-get? identity-metadata identity)
)

(define-read-only (get-following-status (follower principal) (following principal))
  (map-get? identity-relationships { follower: follower, following: following })
)

(define-read-only (get-identity-count)
  (var-get identity-count)
)

(define-read-only (is-identity-registered (identity principal))
  (is-some (map-get? identities identity))
)

(define-read-only (is-identity-verified (identity principal))
  (get verification-status (unwrap! (map-get? identities identity) false))
)