
;; STX-Blockgrounds

;; Contract Name
(define-constant CONTRACT-NAME "STX-Blockgrounds")
(define-constant CONTRACT-VERSION "1.0.0")

;; Error Constants
(define-constant err-owner-only (err u100))
(define-constant err-not-token-owner (err u101))
(define-constant err-token-not-found (err u102))
(define-constant err-already-rented (err u103))
(define-constant err-not-rented (err u104))
(define-constant err-rental-expired (err u105))
(define-constant err-invalid-rental-period (err u106))
(define-constant contract-owner tx-sender)

(define-constant MAX-RENTAL-PERIOD u52560) ;; example: max 1 year (52560 blocks)
(define-constant err-exceeds-max-rental (err u404))
(define-constant err-invalid-price (err u405))

;; Data Variables
(define-data-var last-token-id uint u0)
(define-map tokens
    { token-id: uint } 
    { owner: principal, uri: (string-utf8 256) })

(define-map rental-details
    { token-id: uint }
    {
        tenant: (optional principal),
        rental-start: (optional uint),
        rental-end: (optional uint),
        rental-price: (optional uint)
    })

;; Contract Info Functions
(define-read-only (get-contract-info)
    (ok {
        name: CONTRACT-NAME,
        version: CONTRACT-VERSION,
        owner: contract-owner
    }))

;; SIP-009 NFT Trait Functions
(define-read-only (get-last-token-id)
    (ok (var-get last-token-id)))

(define-read-only (get-token-uri (token-id uint))
    (match (map-get? tokens { token-id: token-id })
        entry (ok (get uri entry))
        (err err-token-not-found)))

(define-read-only (get-owner (token-id uint))
    (match (map-get? tokens { token-id: token-id })
        entry (ok (get owner entry))
        (err err-token-not-found)))

;; Rental Management Functions
(define-read-only (get-rental-details (token-id uint))
    (match (map-get? rental-details { token-id: token-id })
        entry (ok entry)
        (err err-token-not-found)))

(define-public (mint-stx-virtual-land (recipient principal) (uri (string-utf8 256)))
    (let ((token-id (+ (var-get last-token-id) u1)))
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (map-set tokens
            { token-id: token-id }
            { owner: recipient, uri: uri })
        (map-set rental-details
            { token-id: token-id }
            {
                tenant: none,
                rental-start: none,
                rental-end: none,
                rental-price: none
            })
        (var-set last-token-id token-id)
        (ok token-id)))


(define-public (list-virtual-land-for-rent (token-id uint) (price uint))
    (let ((token-owner (unwrap! (get-owner token-id) err-token-not-found)))
        (begin
            ;; Check if sender is token owner
            (asserts! (is-eq tx-sender token-owner) err-not-token-owner)

            ;; Get current rental details
            (match (map-get? rental-details { token-id: token-id })
                rental 
                    (begin
                        ;; Check if not already rented
                        (asserts! (is-none (get tenant rental)) err-already-rented)
                        ;; Update rental details
                        (map-set rental-details
                            { token-id: token-id }
                            {
                                tenant: none,
                                rental-start: none,
                                rental-end: none,
                                rental-price: (some price)
                            })
                        (ok true))
                ;; If no rental details exist, create new entry
                (begin
                    (map-set rental-details
                        { token-id: token-id }
                        {
                            tenant: none,
                            rental-start: none,
                            rental-end: none,
                            rental-price: (some price)
                        })
                    (ok true))))))


(define-public (rent-virtual-land (token-id uint) (rental-period uint))
    (let (
        (token-owner (unwrap! (get-owner token-id) err-token-not-found))
        (rental (unwrap! (map-get? rental-details { token-id: token-id }) err-token-not-found))
        (price (unwrap! (get rental-price rental) err-token-not-found))
        (current-block-height stacks-block-height)  ;; block-height is already a uint
        (rental-end-height (+ stacks-block-height rental-period))
    )
        (begin
            ;; Check if land is not already rented
            (asserts! (is-none (get tenant rental)) err-already-rented)

            ;; Validate rental period
            (asserts! (> rental-period u0) err-invalid-rental-period)

            ;; Optional: Add maximum rental period check
            (asserts! (<= rental-period MAX-RENTAL-PERIOD) err-exceeds-max-rental)

            ;; Check if price is valid
            (asserts! (> price u0) err-invalid-price)

            ;; Transfer rental payment in STX
            (try! (stx-transfer? price tx-sender token-owner))

            ;; Update rental details
            (ok (map-set rental-details
                { token-id: token-id }
                {
                    tenant: (some tx-sender),
                    rental-start: (some current-block-height),
                    rental-end: (some rental-end-height),
                    rental-price: (some price)
                })))))


(define-constant ERR-NOT-AUTHORIZED (err u406))
(define-constant ERR-RENTAL-NOT-EXPIRED (err u407))

(define-public (end-virtual-land-rental (token-id uint))
    (let (
        (rental (unwrap! (map-get? rental-details { token-id: token-id }) err-token-not-found))
        (current-height stacks-block-height)  ;; block-height is already a uint
        (rental-end-height (unwrap! (get rental-end rental) err-not-rented))
        (current-tenant (unwrap! (get tenant rental) err-not-rented))
    )
        (begin
            ;; Check if land is currently rented
            (asserts! (is-some (get tenant rental)) err-not-rented)

            ;; Check if rental period has ended
            (asserts! (>= current-height rental-end-height) ERR-RENTAL-NOT-EXPIRED)

            ;; Optional: Check if caller is authorized (either owner or tenant)
            (asserts! (or 
                (is-eq tx-sender current-tenant)
                (is-eq tx-sender (unwrap! (get-owner token-id) err-token-not-found))
            ) ERR-NOT-AUTHORIZED)

            ;; Reset rental details
            (ok (map-set rental-details
                { token-id: token-id }
                {
                    tenant: none,
                    rental-start: none,
                    rental-end: none,
                    rental-price: none
                })))))

;; Read-only helper functions
(define-read-only (is-land-rented (token-id uint))
    (match (map-get? rental-details { token-id: token-id })
        rental (is-some (get tenant rental))
        false))

(define-read-only (get-land-tenant (token-id uint))
    (match (map-get? rental-details { token-id: token-id })
        rental (ok (get tenant rental))
        (err err-token-not-found)))

(define-read-only (get-rental-expiry (token-id uint))
    (match (map-get? rental-details { token-id: token-id })
        rental (ok (get rental-end rental))
        (err err-token-not-found)))

;; Market statistics
(define-read-only (get-total-lands)
    (ok (var-get last-token-id)))

(define-read-only (get-active-rentals)
    (ok (fold check-if-rented (list u1 u2 u3 u4 u5) u0)))

(define-private (check-if-rented (token-id uint) (sum uint))
    (if (is-land-rented token-id)
        (+ sum u1)
        sum))
