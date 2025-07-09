;; Customer Feedback Contract
;; Handles delivery complaints, suggestions, and service improvements

;; Constants
(define-constant CONTRACT-OWNER tx-sender)
(define-constant ERR-UNAUTHORIZED (err u500))
(define-constant ERR-FEEDBACK-NOT-FOUND (err u501))
(define-constant ERR-INVALID-RATING (err u502))
(define-constant ERR-INVALID-CATEGORY (err u503))
(define-constant ERR-ALREADY-RESPONDED (err u504))

;; Data Variables
(define-data-var next-feedback-id uint u1)
(define-data-var next-survey-id uint u1)

;; Customer feedback records
(define-map customer-feedback
  { feedback-id: uint }
  {
    customer: principal,
    category: (string-ascii 30), ;; "complaint", "suggestion", "compliment", "question"
    subject: (string-ascii 100),
    description: (string-ascii 500),
    priority: uint, ;; 1-5 scale
    delivery-id: (optional uint),
    driver: (optional principal),
    status: (string-ascii 20), ;; "open", "in-progress", "resolved", "closed"
    created-at: uint,
    updated-at: uint,
    response: (optional (string-ascii 500)),
    responded-by: (optional principal),
    satisfaction-rating: (optional uint)
  }
)

;; Service improvement suggestions
(define-map improvement-suggestions
  { suggestion-id: uint }
  {
    customer: principal,
    title: (string-ascii 100),
    description: (string-ascii 500),
    category: (string-ascii 30), ;; "delivery", "app", "service", "pricing"
    votes: uint,
    status: (string-ascii 20), ;; "submitted", "under-review", "approved", "implemented", "rejected"
    implementation-notes: (optional (string-ascii 300)),
    created-at: uint,
    implemented-at: (optional uint)
  }
)

;; Customer satisfaction surveys
(define-map satisfaction-surveys
  { survey-id: uint }
  {
    customer: principal,
    overall-satisfaction: uint, ;; 1-5 scale
    delivery-quality: uint,
    timeliness: uint,
    customer-service: uint,
    value-for-money: uint,
    likelihood-to-recommend: uint, ;; 1-10 scale
    additional-comments: (optional (string-ascii 300)),
    survey-date: uint
  }
)

;; Feedback categories and their handling priorities
(define-map feedback-categories
  { category: (string-ascii 30) }
  {
    priority-level: uint,
    auto-escalate: bool,
    response-time-hours: uint,
    description: (string-ascii 100)
  }
)

;; Feedback token for rewards
(define-fungible-token feedback-token)

;; Initialize feedback categories
(map-set feedback-categories
  { category: "complaint" }
  {
    priority-level: u5,
    auto-escalate: true,
    response-time-hours: u24,
    description: "Customer complaints requiring immediate attention"
  }
)

(map-set feedback-categories
  { category: "suggestion" }
  {
    priority-level: u2,
    auto-escalate: false,
    response-time-hours: u72,
    description: "Customer suggestions for service improvement"
  }
)

(map-set feedback-categories
  { category: "compliment" }
  {
    priority-level: u1,
    auto-escalate: false,
    response-time-hours: u48,
    description: "Positive feedback and compliments"
  }
)

(map-set feedback-categories
  { category: "question" }
  {
    priority-level: u3,
    auto-escalate: false,
    response-time-hours: u48,
    description: "General questions about service"
  }
)

;; Public Functions

;; Submit customer feedback
(define-public (submit-feedback
  (category (string-ascii 30))
  (subject (string-ascii 100))
  (description (string-ascii 500))
  (delivery-id (optional uint))
  (driver (optional principal)))
  (let (
    (feedback-id (var-get next-feedback-id))
    (category-data (unwrap! (map-get? feedback-categories { category: category }) ERR-INVALID-CATEGORY))
    (priority (get priority-level category-data))
  )
    (map-set customer-feedback
      { feedback-id: feedback-id }
      {
        customer: tx-sender,
        category: category,
        subject: subject,
        description: description,
        priority: priority,
        delivery-id: delivery-id,
        driver: driver,
        status: "open",
        created-at: block-height,
        updated-at: block-height,
        response: none,
        responded-by: none,
        satisfaction-rating: none
      }
    )

    (var-set next-feedback-id (+ feedback-id u1))

    ;; Reward customer for providing feedback
    (try! (ft-mint? feedback-token u25 tx-sender))

    (ok feedback-id)
  )
)

;; Respond to customer feedback (admin only)
(define-public (respond-to-feedback
  (feedback-id uint)
  (response (string-ascii 500)))
  (let (
    (feedback-data (unwrap! (map-get? customer-feedback { feedback-id: feedback-id }) ERR-FEEDBACK-NOT-FOUND))
  )
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-UNAUTHORIZED)
    (asserts! (is-none (get response feedback-data)) ERR-ALREADY-RESPONDED)

    (map-set customer-feedback
      { feedback-id: feedback-id }
      (merge feedback-data {
        status: "resolved",
        response: (some response),
        responded-by: (some tx-sender),
        updated-at: block-height
      })
    )

    (ok true)
  )
)

;; Submit satisfaction survey
(define-public (submit-satisfaction-survey
  (overall-satisfaction uint)
  (delivery-quality uint)
  (timeliness uint)
  (customer-service uint)
  (value-for-money uint)
  (likelihood-to-recommend uint)
  (additional-comments (optional (string-ascii 300))))
  (let ((survey-id (var-get next-survey-id)))
    (asserts! (and (>= overall-satisfaction u1) (<= overall-satisfaction u5)) ERR-INVALID-RATING)
    (asserts! (and (>= delivery-quality u1) (<= delivery-quality u5)) ERR-INVALID-RATING)
    (asserts! (and (>= timeliness u1) (<= timeliness u5)) ERR-INVALID-RATING)
    (asserts! (and (>= customer-service u1) (<= customer-service u5)) ERR-INVALID-RATING)
    (asserts! (and (>= value-for-money u1) (<= value-for-money u5)) ERR-INVALID-RATING)
    (asserts! (and (>= likelihood-to-recommend u1) (<= likelihood-to-recommend u10)) ERR-INVALID-RATING)

    (map-set satisfaction-surveys
      { survey-id: survey-id }
      {
        customer: tx-sender,
        overall-satisfaction: overall-satisfaction,
        delivery-quality: delivery-quality,
        timeliness: timeliness,
        customer-service: customer-service,
        value-for-money: value-for-money,
        likelihood-to-recommend: likelihood-to-recommend,
        additional-comments: additional-comments,
        survey-date: block-height
      }
    )

    (var-set next-survey-id (+ survey-id u1))

    ;; Reward customer for completing survey
    (try! (ft-mint? feedback-token u50 tx-sender))

    (ok survey-id)
  )
)

;; Submit improvement suggestion
(define-public (submit-improvement-suggestion
  (title (string-ascii 100))
  (description (string-ascii 500))
  (category (string-ascii 30)))
  (let ((suggestion-id (var-get next-feedback-id))) ;; Reusing counter for simplicity
    (map-set improvement-suggestions
      { suggestion-id: suggestion-id }
      {
        customer: tx-sender,
        title: title,
        description: description,
        category: category,
        votes: u0,
        status: "submitted",
        implementation-notes: none,
        created-at: block-height,
        implemented-at: none
      }
    )

    (var-set next-feedback-id (+ suggestion-id u1))

    ;; Reward customer for suggestion
    (try! (ft-mint? feedback-token u30 tx-sender))

    (ok suggestion-id)
  )
)

;; Vote on improvement suggestion
(define-public (vote-on-suggestion (suggestion-id uint))
  (let (
    (suggestion-data (unwrap! (map-get? improvement-suggestions { suggestion-id: suggestion-id }) ERR-FEEDBACK-NOT-FOUND))
  )
    (map-set improvement-suggestions
      { suggestion-id: suggestion-id }
      (merge suggestion-data {
        votes: (+ (get votes suggestion-data) u1)
      })
    )

    ;; Small reward for voting
    (try! (ft-mint? feedback-token u5 tx-sender))

    (ok true)
  )
)

;; Rate feedback response satisfaction
(define-public (rate-feedback-satisfaction (feedback-id uint) (rating uint))
  (let (
    (feedback-data (unwrap! (map-get? customer-feedback { feedback-id: feedback-id }) ERR-FEEDBACK-NOT-FOUND))
  )
    (asserts! (is-eq (get customer feedback-data) tx-sender) ERR-UNAUTHORIZED)
    (asserts! (and (>= rating u1) (<= rating u5)) ERR-INVALID-RATING)
    (asserts! (is-some (get response feedback-data)) ERR-UNAUTHORIZED)

    (map-set customer-feedback
      { feedback-id: feedback-id }
      (merge feedback-data {
        satisfaction-rating: (some rating),
        updated-at: block-height
      })
    )

    ;; Reward for rating satisfaction
    (try! (ft-mint? feedback-token u10 tx-sender))

    (ok true)
  )
)

;; Read-only functions

(define-read-only (get-feedback (feedback-id uint))
  (map-get? customer-feedback { feedback-id: feedback-id })
)

(define-read-only (get-satisfaction-survey (survey-id uint))
  (map-get? satisfaction-surveys { survey-id: survey-id })
)

(define-read-only (get-improvement-suggestion (suggestion-id uint))
  (map-get? improvement-suggestions { suggestion-id: suggestion-id })
)

(define-read-only (get-feedback-category (category (string-ascii 30)))
  (map-get? feedback-categories { category: category })
)

(define-read-only (calculate-average-satisfaction)
  ;; Simplified calculation - in practice would aggregate all surveys
  u4 ;; Placeholder return value
)

(define-read-only (get-feedback-stats-for-customer (customer principal))
  ;; In practice, would aggregate feedback data for the customer
  {
    total-feedback: u0,
    complaints: u0,
    suggestions: u0,
    compliments: u0,
    average-satisfaction: u0
  }
)

(define-read-only (is-feedback-urgent (feedback-id uint))
  (match (map-get? customer-feedback { feedback-id: feedback-id })
    feedback-data (>= (get priority feedback-data) u4)
    false
  )
)
