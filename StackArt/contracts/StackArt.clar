;; StackArt NFT Protocol Smart Contract
(define-trait StackArt-protocol
  (
    (move (uint principal principal) (response bool uint))
    (fetch-holder (uint) (response (optional principal) uint))
    (fetch-max-id () (response uint uint))
    (fetch-metadata-uri (uint) (response (optional (string-utf8 256)) uint))
  )
)

;; System Parameters
(define-constant admin tx-sender)
(define-constant err-unauthorized (err u100))
(define-constant err-invalid-holder (err u101))
(define-constant err-missing-asset (err u102))
(define-constant err-no-listing (err u103))
(define-constant err-low-balance (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-system-paused (err u106))
(define-constant err-missing-uri (err u107))
(define-constant err-invalid-duration (err u108))
(define-constant err-admin-transfer (err u109))

;; Platform Configuration
(define-data-var market-active bool true)
(define-data-var commission-rate uint u300)
(define-data-var total-minted uint u0)

;; Asset Registry
(define-non-fungible-token phoenix-asset uint)

;; Asset Records
(define-map asset-registry
  uint
  {
    holder: principal,
    metadata: (string-utf8 256),
    creator: principal
  }
)

;; Market Entries
(define-map market-listings
  uint
  {
    price: uint,
    seller: principal,
    expires: uint
  }
)

;; Internal Validators
(define-private (check-ownership (asset-id uint))
  (match (map-get? asset-registry asset-id)
    record (is-eq tx-sender (get holder record))
    false
  )
)

(define-private (asset-exists (asset-id uint))
  (is-some (map-get? asset-registry asset-id))
)

(define-private (execute-transfer (asset-id uint) (sender principal) (recipient principal))
  (let ((record (map-get? asset-registry asset-id)))
    (asserts! (is-some record) err-missing-asset)
    (try! (nft-transfer? phoenix-asset asset-id sender recipient))
    (map-set asset-registry asset-id
      (merge (unwrap-panic record)
             {holder: recipient}))
    (ok true)
  )
)

(define-private (calculate-fee (sale-price uint))
  (/ (* sale-price (var-get commission-rate)) u10000)
)

;; Asset Transfer
(define-public (transfer-asset (asset-id uint) (from principal) (to principal))
  (begin
    (asserts! (var-get market-active) err-system-paused)
    (asserts! (is-eq tx-sender from) err-invalid-holder)
    (asserts! (check-ownership asset-id) err-invalid-holder)
    (asserts! (not (is-eq to admin)) err-admin-transfer)
    (execute-transfer asset-id from to)
  )
)

;; Create New Asset
(define-public (mint-asset (uri-data (string-utf8 256)))
  (let ((new-id (+ (var-get total-minted) u1)))
    (asserts! (var-get market-active) err-system-paused)
    (asserts! (> (len uri-data) u0) err-missing-uri)
    (try! (nft-mint? phoenix-asset new-id tx-sender))
    (map-set asset-registry new-id
      {
        holder: tx-sender,
        metadata: uri-data,
        creator: tx-sender
      })
    (var-set total-minted new-id)
    (ok new-id)
  )
)

;; Create Market Listing
(define-public (create-listing (asset-id uint) (ask-price uint) (duration uint))
  (begin
    (asserts! (var-get market-active) err-system-paused)
    (asserts! (> ask-price u0) err-invalid-amount)
    (asserts! (check-ownership asset-id) err-invalid-holder)
    (asserts! (> duration u0) err-invalid-duration)
    (map-set market-listings asset-id
      {
        price: ask-price,
        seller: tx-sender,
        expires: (+ stacks-block-height duration)
      })
    (ok true)
  )
)

;; Remove Listing
(define-public (cancel-listing (asset-id uint))
  (begin
    (asserts! (var-get market-active) err-system-paused)
    (asserts! (check-ownership asset-id) err-invalid-holder)
    (map-delete market-listings asset-id)
    (ok true)
  )
)

;; Execute Purchase
(define-public (buy-asset (asset-id uint))
  (let (
    (listing (unwrap! (map-get? market-listings asset-id) err-no-listing))
    (ask-price (get price listing))
    (owner (get seller listing))
    (deadline (get expires listing))
  )
    (asserts! (var-get market-active) err-system-paused)
    ;; Add validation to check if asset exists before proceeding
    (asserts! (asset-exists asset-id) err-missing-asset)
    (asserts! (<= stacks-block-height deadline) err-no-listing)
    (asserts! (>= (stx-get-balance tx-sender) ask-price) err-low-balance)
    ;; Additional validation: ensure the seller in listing matches the actual asset owner
    (let ((asset-record (unwrap! (map-get? asset-registry asset-id) err-missing-asset)))
      (asserts! (is-eq owner (get holder asset-record)) err-invalid-holder)
      (let (
        (platform-fee (calculate-fee ask-price))
        (seller-amount (- ask-price platform-fee))
      )
        (try! (stx-transfer? seller-amount tx-sender owner))
        (try! (stx-transfer? platform-fee tx-sender admin))
        (try! (execute-transfer asset-id owner tx-sender))
        (map-delete market-listings asset-id)
        (ok true)
      )
    )
  )
)

;; Administrative Functions
(define-public (update-commission (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender admin) err-unauthorized)
    (asserts! (<= new-rate u1500) err-invalid-amount)
    (var-set commission-rate new-rate)
    (ok true)
  )
)

(define-public (toggle-market)
  (begin
    (asserts! (is-eq tx-sender admin) err-unauthorized)
    (var-set market-active (not (var-get market-active)))
    (ok true)
  )
)

(define-public (prolong-listing (asset-id uint) (additional-time uint))
  (let ((listing (unwrap! (map-get? market-listings asset-id) err-no-listing)))
    (asserts! (is-eq tx-sender (get seller listing)) err-invalid-holder)
    (map-set market-listings asset-id
      (merge listing {expires: (+ stacks-block-height additional-time)}))
    (ok true)
  )
)

;; Query Functions
(define-read-only (get-asset-info (asset-id uint))
  (map-get? asset-registry asset-id)
)

(define-read-only (get-listing-info (asset-id uint))
  (map-get? market-listings asset-id)
)

(define-read-only (get-asset-owner (asset-id uint))
  (match (map-get? asset-registry asset-id)
    record (ok (some (get holder record)))
    (ok none)
  )
)

(define-read-only (get-total-supply)
  (ok (var-get total-minted))
)

(define-read-only (get-asset-uri (asset-id uint))
  (match (map-get? asset-registry asset-id)
    record (ok (some (get metadata record)))
    (ok none)
  )
)