;; CreativeShare: Decentralized Creator Revenue Sharing Platform
;; Contract for managing revenue sharing between collaborators on creative projects

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-invalid-percentage (err u102))
(define-constant err-already-exists (err u103))

;; Data Maps
(define-map projects 
    { project-id: uint }
    {
        owner: principal,
        title: (string-ascii 256),
        content-hash: (buff 32),
        license-type: (string-ascii 64),
        total-revenue: uint,
        is-active: bool
    }
)

(define-map collaborators
    { project-id: uint, collaborator: principal }
    {
        share-percentage: uint,
        earnings: uint,
        role: (string-ascii 64)
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

;; Project Management Functions
(define-public (create-project (project-id uint) (title (string-ascii 256)) (content-hash (buff 32)) (license-type (string-ascii 64)))
    (let ((project-exists (get is-active (map-get? projects { project-id: project-id }))))
        (asserts! (is-none project-exists) err-already-exists)
        (ok (map-set projects
            { project-id: project-id }
            {
                owner: tx-sender,
                title: title,
                content-hash: content-hash,
                license-type: license-type,
                total-revenue: u0,
                is-active: true
            }
        ))
    )
)

(define-public (add-collaborator (project-id uint) (collaborator principal) (share-percentage uint) (role (string-ascii 64)))
    (let ((project (map-get? projects { project-id: project-id })))
        (asserts! (is-some project) err-not-found)
        (asserts! (< share-percentage u101) err-invalid-percentage)
        (asserts! (is-eq tx-sender (get owner (unwrap-panic project))) err-owner-only)

        (ok (map-set collaborators
            { project-id: project-id, collaborator: collaborator }
            {
                share-percentage: share-percentage,
                earnings: u0,
                role: role
            }
        ))
    )
)

;; Revenue Distribution Functions
(define-public (distribute-revenue (project-id uint) (amount uint))
    (let (
        (project (unwrap! (map-get? projects { project-id: project-id }) err-not-found))
        (current-total (get total-revenue project))
    )
        ;; Update total project revenue
        (map-set projects 
            { project-id: project-id }
            (merge project { total-revenue: (+ current-total amount) })
        )

        ;; TODO: Implement revenue distribution logic to collaborators based on share percentages
        (ok true)
    )
)

;; Licensing Functions
(define-public (record-license-usage (project-id uint) (usage-type (string-ascii 64)) (payment uint))
    (let ((project (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
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

;; Read-Only Functions
(define-read-only (get-project-details (project-id uint))
    (map-get? projects { project-id: project-id })
)

(define-read-only (get-collaborator-info (project-id uint) (collaborator principal))
    (map-get? collaborators { project-id: project-id, collaborator: collaborator })
)

(define-read-only (get-license-history (project-id uint) (licensee principal))
    (map-get? licensing-history { project-id: project-id, licensee: licensee })
)