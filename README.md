# ScholarshipDis. – Decentralized Scholarship & Grant Distribution


# First Pres Notes
- Consider a seed donor, or donor committee, at min. Seeded constructor
- Hash out the voting threshold


## Group Members

- **Victoria Dynak** – victoria.dynak61@myhunter.cuny.edu  
- **Sayad Islam** – sayad.islam97@myhunter.cuny.edu
---

## Purpose of the Contract

`ScholarshipDis.` is a decentralized smart contract that manages scholarship or grant distribution without relying on a single trusted organization.

The contract allows:

- **Donors** to send ETH into a public scholarship pool.  
- **Students** to apply for the scholarship by submitting an IPFS hash or content hash that points to their application materials.  
- **Committee members** to vote on each application.  
- Once voting is complete, the contract **automatically releases the funds** to the winning applicant according to the rules encoded in the contract.

This setup reduces the risk of corruption or mismanagement and makes the scholarship process transparent, rule-based, and auditable on-chain.

---

## Why Use Blockchain for This?

- **Transparency:** Every donation and payout is visible on the blockchain. Donors can verify how much was raised and that funds were actually sent to the chosen student.
- **Trustless Fund Handling:** The ETH is held by the contract itself, not by a person or organization. Funds can only be released when the voting rules are met.
- **Immutable Applications:** Application submissions are referenced by hashes (for example, IPFS). Once submitted, they cannot be edited or deleted on-chain.
- **Auditable Voting:** Committee votes are recorded as events. Anyone can see how many votes each application received and confirm that the winner was chosen fairly.

---

### Real-World Problems This Contract Can Solve

Below are two actual cases where scholarship funds were mismanaged or mishandled. Both problems could have been prevented with a transparent, decentralized system like our ScholarshipFund contract.

#### **1. U.S. COVID Emergency Student Grant Misallocation (HEERF Program)**

**What happened:**
- Colleges received federal money to distribute emergency grants to students during COVID.
- Several schools delayed payments or misreported which students received funds.
- Some students who qualified never received grants due to administrative errors or opaque internal processes.

**The problem:**
- No public record of who applied or who was approved.
- Funds were distributed (or not distributed) privately by administrators.
- Students had no way to verify delays or missing payments.

**How blockchain would help:**
- Transparent donation and payout history.
- Applications stored as immutable hashes after submission.
- Automatic payout rules prevent selective delays or favoritism.
- Anyone can audit how much money was sent and to whom.

---

#### **2. National Merit Scholarship Notification & Distribution Delays (U.S.)**

**What happened:**
- Multiple school districts were found to have delayed or withheld scholarship notifications.
- This prevented students from accessing scholarship money or listing awards on college applications.
- In some cases, scholarship funds were “held” without clear explanation to students.

**The problem:**
- Scholarship information controlled entirely by school administrators.
- Students had no visibility into award status.
- No audit trail to prove a notification or payment was delayed.

**How blockchain would help:**
- Public, time-stamped record of applications and voting outcomes.
- Automated and rule-based payouts when criteria are met.
- No one can “withhold” or “delay” a scholarship decision.
- Full transparency ensures equal treatment for all applicants.

---

## Contract Interface

The interface under the "contracts" folder defines the events and function headers for `ScholarshipFund`. 
It will be further developed with logic in Part 2 of Assignment 4.
