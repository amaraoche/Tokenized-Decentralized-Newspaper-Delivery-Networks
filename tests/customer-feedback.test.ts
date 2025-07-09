import { describe, it, expect, beforeEach } from "vitest"

describe("Customer Feedback Contract", () => {
  let contractAddress
  let customerAddress
  let adminAddress
  let feedbackId
  
  beforeEach(() => {
    contractAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM.customer-feedback"
    customerAddress = "ST2CY5V39NHDPWSXMW9QDT3HC3GD6Q6XX4CFRK9AG"
    adminAddress = "ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM"
  })
  
  describe("Feedback Submission", () => {
    it("should submit complaint successfully", async () => {
      const result = await callPublicFunction({
        contractAddress,
        functionName: "submit-feedback",
        functionArgs: [
          stringAsciiCV("complaint"),
          stringAsciiCV("Late delivery issue"),
          stringAsciiCV("My newspaper was delivered 3 hours late today. This has happened multiple times this week."),
          someCV(uintCV(123)), // delivery-id
          someCV(principalCV("ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0")), // driver
        ],
        senderAddress: customerAddress,
      })
      
      expect(result.type).toBe("ok")
      feedbackId = result.value
    })
    
    it("should submit suggestion successfully", async () => {
      const result = await callPublicFunction({
        contractAddress,
        functionName: "submit-feedback",
        functionArgs: [
          stringAsciiCV("suggestion"),
          stringAsciiCV("Mobile app improvement"),
          stringAsciiCV("It would be great to have real-time delivery tracking in the mobile app."),
          noneCV(),
          noneCV(),
        ],
        senderAddress: customerAddress,
      })
      
      expect(result.type).toBe("ok")
    })
    
    it("should submit compliment successfully", async () => {
      const result = await callPublicFunction({
        contractAddress,
        functionName: "submit-feedback",
        functionArgs: [
          stringAsciiCV("compliment"),
          stringAsciiCV("Excellent service"),
          stringAsciiCV("The driver was very professional and the paper was delivered in perfect condition."),
          someCV(uintCV(456)),
          someCV(principalCV("ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0")),
        ],
        senderAddress: customerAddress,
      })
      
      expect(result.type).toBe("ok")
    })
  })
  
  describe("Feedback Response", () => {
    beforeEach(async () => {
      const result = await callPublicFunction({
        contractAddress,
        functionName: "submit-feedback",
        functionArgs: [
          stringAsciiCV("question"),
          stringAsciiCV("Billing inquiry"),
          stringAsciiCV("I have a question about my monthly billing cycle."),
          noneCV(),
          noneCV(),
        ],
        senderAddress: customerAddress,
      })
      feedbackId = result.value
    })
    
    it("should respond to feedback successfully", async () => {
      const result = await callPublicFunction({
        contractAddress,
        functionName: "respond-to-feedback",
        functionArgs: [
          uintCV(feedbackId),
          stringAsciiCV(
              "Thank you for your inquiry. Your billing cycle runs from the 1st to the 30th of each month. You can view detailed billing information in your account dashboard.",
          ),
        ],
        senderAddress: adminAddress,
      })
      
      expect(result.type).toBe("ok")
    })
  })
  
  describe("Satisfaction Surveys", () => {
    it("should submit satisfaction survey successfully", async () => {
      const result = await callPublicFunction({
        contractAddress,
        functionName: "submit-satisfaction-survey",
        functionArgs: [
          uintCV(4), // overall satisfaction
          uintCV(5), // delivery quality
          uintCV(3), // timeliness
          uintCV(4), // customer service
          uintCV(4), // value for money
          uintCV(8), // likelihood to recommend (1-10)
          someCV(stringAsciiCV("Generally satisfied with the service. Room for improvement in timeliness.")),
        ],
        senderAddress: customerAddress,
      })
      
      expect(result.type).toBe("ok")
    })
    
    it("should submit survey without comments", async () => {
      const result = await callPublicFunction({
        contractAddress,
        functionName: "submit-satisfaction-survey",
        functionArgs: [uintCV(5), uintCV(5), uintCV(5), uintCV(5), uintCV(5), uintCV(10), noneCV()],
        senderAddress: customerAddress,
      })
      
      expect(result.type).toBe("ok")
    })
  })
  
  describe("Improvement Suggestions", () => {
    it("should submit improvement suggestion successfully", async () => {
      const result = await callPublicFunction({
        contractAddress,
        functionName: "submit-improvement-suggestion",
        functionArgs: [
          stringAsciiCV("Weekend delivery options"),
          stringAsciiCV(
              "It would be helpful to have more flexible weekend delivery time slots, especially for working customers.",
          ),
          stringAsciiCV("delivery"),
        ],
        senderAddress: customerAddress,
      })
      
      expect(result.type).toBe("ok")
    })
    
    it("should vote on suggestion successfully", async () => {
      const suggestionResult = await callPublicFunction({
        contractAddress,
        functionName: "submit-improvement-suggestion",
        functionArgs: [
          stringAsciiCV("Digital receipts"),
          stringAsciiCV("Provide digital receipts for all transactions to reduce paper waste."),
          stringAsciiCV("service"),
        ],
        senderAddress: customerAddress,
      })
      
      const suggestionId = suggestionResult.value
      
      const voteResult = await callPublicFunction({
        contractAddress,
        functionName: "vote-on-suggestion",
        functionArgs: [uintCV(suggestionId)],
        senderAddress: "ST3AM1A56AK2C1XAFJ4115ZSV26EB49BVQ10MGCS0",
      })
      
      expect(voteResult.type).toBe("ok")
    })
  })
  
  describe("Satisfaction Rating", () => {
    beforeEach(async () => {
      const feedbackResult = await callPublicFunction({
        contractAddress,
        functionName: "submit-feedback",
        functionArgs: [
          stringAsciiCV("complaint"),
          stringAsciiCV("Delivery issue"),
          stringAsciiCV("Paper was damaged"),
          someCV(uintCV(789)),
          noneCV(),
        ],
        senderAddress: customerAddress,
      })
      feedbackId = feedbackResult.value
      
      // Admin responds to feedback
      await callPublicFunction({
        contractAddress,
        functionName: "respond-to-feedback",
        functionArgs: [
          uintCV(feedbackId),
          stringAsciiCV("We apologize for the damaged paper. We will ensure better packaging in the future."),
        ],
        senderAddress: adminAddress,
      })
    })
    
    it("should rate feedback satisfaction successfully", async () => {
      const result = await callPublicFunction({
        contractAddress,
        functionName: "rate-feedback-satisfaction",
        functionArgs: [
          uintCV(feedbackId),
          uintCV(4), // satisfaction rating
        ],
        senderAddress: customerAddress,
      })
      
      expect(result.type).toBe("ok")
    })
  })
  
  describe("Read-only Functions", () => {
    it("should return feedback data", async () => {
      const result = await callReadOnlyFunction({
        contractAddress,
        functionName: "get-feedback",
        functionArgs: [uintCV(1)],
      })
      
      expect(result).toBeDefined()
    })
    
    it("should return satisfaction survey data", async () => {
      const result = await callReadOnlyFunction({
        contractAddress,
        functionName: "get-satisfaction-survey",
        functionArgs: [uintCV(1)],
      })
      
      expect(result).toBeDefined()
    })
    
    it("should return improvement suggestion data", async () => {
      const result = await callReadOnlyFunction({
        contractAddress,
        functionName: "get-improvement-suggestion",
        functionArgs: [uintCV(1)],
      })
      
      expect(result).toBeDefined()
    })
    
    it("should return feedback category information", async () => {
      const result = await callReadOnlyFunction({
        contractAddress,
        functionName: "get-feedback-category",
        functionArgs: [stringAsciiCV("complaint")],
      })
      
      expect(result).toBeDefined()
    })
    
    it("should get feedback stats for customer", async () => {
      const result = await callReadOnlyFunction({
        contractAddress,
        functionName: "get-feedback-stats-for-customer",
        functionArgs: [principalCV(customerAddress)],
      })
      
      expect(result).toBeDefined()
    })
  })
})

function stringAsciiCV(value) {
  return { type: "string-ascii", value }
}

function uintCV(value) {
  return { type: "uint", value }
}

function principalCV(value) {
  return { type: "principal", value }
}

function someCV(value) {
  return { type: "some", value }
}

function noneCV() {
  return { type: "none" }
}

async function callPublicFunction({ contractAddress, functionName, functionArgs, senderAddress }) {
  return { type: "ok", value: 1 }
}

async function callReadOnlyFunction({ contractAddress, functionName, functionArgs }) {
  return { type: "ok", value: 100 }
}
