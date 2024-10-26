;; CreatS: Decentralized Creator Revenue Sharing Platform
;; Enhanced version with additional safety checks and improvements

;; Constants
(define-constant contract-owner tx-sender)
(define-constant MAX-PROJECT-ID u1000000)
(define-constant MIN-SHARE-PERCENTAGE u1)
(define-constant MAX-SHARE-PERCENTAGE u100)

;; Error Codes
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
(define-constant err-invalid-content-hash (err u110))
(define-constant err-invalid-role (err u111))
(define-constant err-project-inactive (err u112))
(define-constant err-collaborator-exists (err u113))
(define-constant err-no-earnings (err u114))
(define-constant err-withdrawal-failed (err u115))

;; Data Variables
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
        created-at: uint,
        total-collaborators: uint,
        total-distributions: uint
    }
)

(define-map collaborators
    { project-id: uint, collaborator: principal }
    {
        share-percentage: uint,
        earnings: uint,
        role: (string-ascii 64),
        added-at: uint,
        last-distribution: uint
    }
)

(define-map licensing-history
    { project-id: uint, licensee: principal }
    {
        timestamp: uint,
        payment: uint,
        usage-type: (string-ascii 64),
        distribution-complete: bool
    }
)

;; Enhanced Validation Functions
(define-private (validate-project-id (project-id uint))
    (and 
        (> project-id u0)
        (<= project-id MAX-PROJECT-ID)
    )
)

(define-private (validate-title (title (string-ascii 256)))
    (and 
        (not (is-eq title ""))
        (<= (len title) u256)
        (> (len title) u2)  ;; Minimum length requirement
    )
)

(define-private (validate-content-hash (content-hash (buff 32)))
    (and
        (not (is-eq content-hash 0x)) ;; Check if not empty
        (is-eq (len content-hash) u32) ;; Verify exact length
    )
)

(define-private (validate-license-type (license-type (string-ascii 64)))
    (and 
        (not (is-eq license-type ""))
        (<= (len license-type) u64)
        (> (len license-type) u2)
    )
)

(define-private (validate-role (role (string-ascii 64)))
    (and 
        (not (is-eq role ""))
        (<= (len role) u64)
        (> (len role) u2)
    )
)

(define-private (validate-share-percentage (share-percentage uint))
    (and 
        (>= share-percentage MIN-SHARE-PERCENTAGE)
        (<= share-percentage MAX-SHARE-PERCENTAGE)
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

;; Enhanced Project Management Functions
(define-public (create-project (title (string-ascii 256)) (content-hash (buff 32)) (license-type (string-ascii 64)))
    (begin
        (asserts! (validate-title title) err-invalid-title)
        (asserts! (validate-content-hash content-hash) err-invalid-content-hash)
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
                    created-at: block-height,
                    total-collaborators: u0,
                    total-distributions: u0
                }
            ))
        )
    )
)

(define-public (add-collaborator (project-id uint) (collaborator principal) (share-percentage uint) (role (string-ascii 64)))
    (begin
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (asserts! (validate-share-percentage share-percentage) err-invalid-percentage)
        (asserts! (validate-role role) err-invalid-role)
        
        (let (
            (project (unwrap! (get-project-details project-id) err-not-found))
            (existing-collaborator (map-get? collaborators { project-id: project-id, collaborator: collaborator }))
        )
            (asserts! (is-eq tx-sender (get owner project)) err-owner-only)
            (asserts! (get is-active project) err-project-inactive)
            (asserts! (is-none existing-collaborator) err-collaborator-exists)
            
            (map-set projects
                { project-id: project-id }
                (merge project { 
                    total-collaborators: (+ (get total-collaborators project) u1)
                })
            )
            
            (ok (map-set collaborators
                { project-id: project-id, collaborator: collaborator }
                {
                    share-percentage: share-percentage,
                    earnings: u0,
                    role: role,
                    added-at: block-height,
                    last-distribution: block-height
                }
            ))
        )
    )
)

;; Enhanced Revenue Distribution Functions
(define-private (calculate-share (amount uint) (percentage uint))
    (/ (* amount percentage) u100)
)

;; New helper function to distribute earnings to collaborators
(define-private (distribute-to-collaborators (project-id uint) (amount uint))
    (let (
        (project (unwrap! (get-project-details project-id) err-not-found))
        (collaborator-info (unwrap! (get-collaborator-info project-id tx-sender) err-not-found))
    )
        ;; Calculate share for the collaborator
        (let (
            (share-amount (calculate-share amount (get share-percentage collaborator-info)))
        )
            ;; Update collaborator's earnings
            (map-set collaborators
                { project-id: project-id, collaborator: tx-sender }
                (merge collaborator-info {
                    earnings: (+ (get earnings collaborator-info) share-amount),
                    last-distribution: block-height
                })
            )
            (ok true)
        )
    )
)

(define-public (distribute-revenue (project-id uint) (amount uint))
    (begin
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (asserts! (validate-amount amount) err-invalid-amount)
        
        (let (
            (project (unwrap! (get-project-details project-id) err-not-found))
        )
            (asserts! (get is-active project) err-project-inactive)
            
            ;; Update project total revenue
            (map-set projects 
                { project-id: project-id }
                (merge project { 
                    total-revenue: (+ (get total-revenue project) amount),
                    total-distributions: (+ (get total-distributions project) u1)
                })
            )
            
            ;; Distribute earnings to collaborators
            (try! (distribute-to-collaborators project-id amount))
            
            (ok true)
        )
    )
)

;; New withdrawal function for collaborators
(define-public (withdraw-earnings (project-id uint))
    (begin
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        
        (let (
            (collaborator-info (unwrap! (get-collaborator-info project-id tx-sender) err-not-found))
            (earnings-amount (get earnings collaborator-info))
        )
            ;; Verify there are earnings to withdraw
            (asserts! (> earnings-amount u0) err-no-earnings)
            
            ;; Reset earnings to zero before transfer
            (map-set collaborators
                { project-id: project-id, collaborator: tx-sender }
                (merge collaborator-info {
                    earnings: u0,
                    last-distribution: block-height
                })
            )
            
            ;; Perform the transfer
            ;; Note: In a real implementation, you would integrate with your chosen
            ;; token contract here using contract-call?
            (ok earnings-amount)
        )
    )
)

;; Enhanced Licensing Functions
(define-public (record-license-usage (project-id uint) (usage-type (string-ascii 64)) (payment uint))
    (begin
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (asserts! (validate-amount payment) err-zero-amount)
        (asserts! (validate-license-type usage-type) err-invalid-license)
        
        (let ((project (unwrap! (get-project-details project-id) err-not-found)))
            (asserts! (get is-active project) err-project-inactive)
            
            (map-set licensing-history
                { project-id: project-id, licensee: tx-sender }
                {
                    timestamp: block-height,
                    payment: payment,
                    usage-type: usage-type,
                    distribution-complete: false
                }
            )
            
            (distribute-revenue project-id payment)
        )
    )
)

;; Enhanced Read-Only Functions
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

;; New read-only function to check pending earnings
(define-read-only (get-pending-earnings (project-id uint) (collaborator principal))
    (begin
        (asserts! (validate-project-id project-id) err-invalid-project-id)
        (let ((collaborator-info (unwrap! (get-collaborator-info project-id collaborator) err-not-found)))
            (ok (get earnings collaborator-info))
        )
    )
)

;; Enhanced Project Status Management
(define-public (deactivate-project (project-id uint))
    (let ((project (unwrap! (get-project-details project-id) err-not-found)))
        (asserts! (is-eq tx-sender (get owner project)) err-owner-only)
        (asserts! (get is-active project) err-project-inactive)
        (ok (map-set projects
            { project-id: project-id }
            (merge project { is-active: false })
        ))
    )
)

(define-public (reactivate-project (project-id uint))
    (let ((project (unwrap! (get-project-details project-id) err-not-found)))
        (asserts! (is-eq tx-sender (get owner project)) err-owner-only)
        (asserts! (not (get is-active project)) err-operation-failed)
        (ok (map-set projects
            { project-id: project-id }
            (merge project { is-active: true })
        ))
    )
)

;; New Utility Functions
(define-read-only (get-current-project-id)
    (ok (var-get next-project-id))
)

(define-read-only (get-project-owner (project-id uint))
    (ok (get owner (unwrap! (map-get? projects { project-id: project-id }) err-not-found)))
)

(define-read-only (get-project-statistics (project-id uint))
    (let ((project (unwrap! (get-project-details project-id) err-not-found)))
        (ok {
            total-revenue: (get total-revenue project),
            total-collaborators: (get total-collaborators project),
            total-distributions: (get total-distributions project),
            is-active: (get is-active project),
            age: (- block-height (get created-at project))
        })
    )
)