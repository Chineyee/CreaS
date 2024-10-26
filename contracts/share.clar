;; CreatS: Decentralized Creator Revenue Sharing Platform
;; Contract for managing revenue sharing between collaborators on creative projects

;; Error Codes
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-percentage (err u102))
(define-constant err-already-exists (err u103))
(define-constant err-invalid-project-id (err u104))
(define-constant err-invalid-amount (err u105))
(define-constant err-invalid-title (err u106))
(define-constant err-invalid-license (err u107))
(define-constant err-zero-amount (err u108))
(define-constant err-operation-failed (err u109))

;; Data Types
(define-data-var next-project-id uint u1)

;; Data Maps
(define-map projects 
    { project-id: uint }
    {
        owner: principal,
        title: (string-ascii 256),
        content-hash: (buff 32),
        license-type: (string-ascii 64),
        total-revenue: uint,
        is-active: bool,
        created-at: uint
    }
)

(define-map collaborators
    { project-id: uint, collaborator: principal }
    {
        share-percentage: uint,
        earnings: uint,
        role: (string-ascii 64),
        added-at: uint
    }
)

(define-map licensing-history
    { project-id: uint, licensee: principal }
    {
        timestamp: uint,
        payment: uint,
        usage-type: (string-ascii 64)
    }
)

;; Helper Functions
(define-private (validate-project-id (project-id uint))
    (and 
        (> project-id u0)
        (<= project-id u1000000)  ;; Set reasonable maximum
    )
)

(define-private (validate-title (title (string-ascii 256)))
    (and 
        (not (is-eq title ""))
        (<= (len title) u256)
    )
)

(define-private (validate-license-type (license-type (string-ascii 64)))
    (and 
        (not (is-eq license-type ""))
        (<= (len license-type) u64)
    )
)

(define-private (validate-share-percentage (share-percentage uint))
    (and 
        (>= share-percentage u1)
        (<= share-percentage u100)
    )
)

(define-private (validate-amount (amount uint))
    (> amount u0)
)

(define-private (increment-project-id)
    (let ((current-id (var-get next-project-id)))
        (var-set next-project-id (+ current-id u1))
        current-id
    )
)

;; Project Management Functions
(define-public (create-project (title (string-ascii 256)) (content-hash (buff 32)) (license-type (string-ascii 64)))
    (begin
        ;; Input validation
        (asserts! (validate-title title) err-invalid-title)
        (asserts! (validate-license-type license-type) err-invalid-license)
        
        (let ((project-id (increment-project-id)))
            (ok (map-set projects
                { project-id: project-id }
                {
                    owner: tx-sender,
                    title: title,
                    content-hash: content-hash,
                    license-type: license-type,
                    total-revenue: u0,
                    is-active: true,
                    created-at: block-height
                }
            ))
        )
    )
)

(define-public (add-collaborator (project-id uint) (collaborator principal) (share-percentage uint) (role (string-ascii 64)))
    (begin
        ;; Input validation
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (asserts! (validate-share-percentage share-percentage) err-invalid-percentage)
        
        (let ((project (unwrap! (get-project-details project-id) err-not-found)))
            (asserts! (is-eq tx-sender (get owner project)) err-owner-only)
            
            (ok (map-set collaborators
                { project-id: project-id, collaborator: collaborator }
                {
                    share-percentage: share-percentage,
                    earnings: u0,
                    role: role,
                    added-at: block-height
                }
            ))
        )
    )
)

;; Revenue Distribution Functions
(define-private (calculate-share (amount uint) (percentage uint))
    (/ (* amount percentage) u100)
)

(define-public (distribute-revenue (project-id uint) (amount uint))
    (begin
        ;; Input validation
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (asserts! (validate-amount amount) err-invalid-amount)
        
        (let (
            (project (unwrap! (get-project-details project-id) err-not-found))
            (current-total (get total-revenue project))
        )
            ;; Update total project revenue
            (map-set projects 
                { project-id: project-id }
                (merge project { total-revenue: (+ current-total amount) })
            )
            
            (ok true)
        )
    )
)

;; Licensing Functions
(define-public (record-license-usage (project-id uint) (usage-type (string-ascii 64)) (payment uint))
    (begin
        ;; Input validation
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (asserts! (validate-amount payment) err-zero-amount)
        (asserts! (validate-license-type usage-type) err-invalid-license)
        
        (let ((project (unwrap! (get-project-details project-id) err-not-found)))
            ;; Set licensing history
            (map-set licensing-history
                { project-id: project-id, licensee: tx-sender }
                {
                    timestamp: block-height,
                    payment: payment,
                    usage-type: usage-type
                }
            )
            ;; Distribute revenue after recording license usage
            (distribute-revenue project-id payment)
        )
    )
)

;; Read-Only Functions
(define-read-only (get-project-details (project-id uint))
    (begin
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (ok (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
    )
)

(define-read-only (get-collaborator-info (project-id uint) (collaborator principal))
    (begin
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (ok (unwrap! (map-get? collaborators 
            { project-id: project-id, collaborator: collaborator }
        ) err-not-found))
    )
)

(define-read-only (get-license-history (project-id uint) (licensee principal))
    (begin
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (ok (unwrap! (map-get? licensing-history 
            { project-id: project-id, licensee: licensee }
        ) err-not-found))
    )
)

;; Additional Helper Functions
(define-read-only (get-current-project-id)
    (ok (var-get next-project-id))
)

(define-read-only (get-project-owner (project-id uint))
    (ok (get owner (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
)

;; Project Status Management
(define-public (deactivate-project (project-id uint))
    (let ((project (unwrap! (get-project-details project-id) err-not-found)))
        (asserts! (is-eq tx-sender (get owner project)) err-owner-only)
        (ok (map-set projects
            { project-id: project-id }
            (merge project { is-active: false })
        ))
    )
)

(define-public (reactivate-project (project-id uint))
    (let ((project (unwrap! (get-project-details project-id) err-not-found)))
        (asserts! (is-eq tx-sender (get owner project)) err-owner-only)
        (ok (map-set projects
            { project-id: project-id }
            (merge project { is-active: true })
        ))
    )
)