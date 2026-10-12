# VaaniVault — Final Product Requirements Document

> Source: VaaniVault PRD v2.pdf. This file preserves the extracted content and ordering of the final PDF. Tables retain their original text layout where applicable.

VaaniVault — Final Product Requirements
  Document
  Community-governed AI data licensing and revenue sharing on Monad · Monad
  Metropolis · Track: Trust, Identity & AI Infrastructure

    Oct 12, 2026    · ​@Lakshmikanth
## At a glance
  VaaniVault is a community-governed licensing layer for AI training data on Monad:
  contributors sign consent with just a phone login, AI teams pay into escrow, the
  community votes without paying gas, and approval pays every contributor and issues a
  verifiable licence in under a second.

  Submission deadline: 13 Oct 2026 (Metropolis, track: Trust, Identity & AI Infrastructure).
  Team: 2 members.
## Final decisions
     Decision                          Choice

     Primary model                     Community-owned datasets with council voting;
                                       individual approval is a small secondary path

     Dataset categories                All categories listable; audio (Tamil voice) fully built
                                       end to end

     Contributor and voter login       Phone or email with embedded wallets (Privy);
                                       MetaMask as fallback

     Gas for contributors and voters   Sponsored: they sign, a relayer submits

     Revenue                           Paid to each contributor individually, by share of
                                       clips, in the approval transaction

     Buyer payment                     Testnet MON from a wallet or an AI agent script;
                                       fiat is roadmap

     Copy protection                   Per-licensee fingerprinted bundles that trace any
                                       leak to its licensee


     Decision                          Choice

     Monad story                       Instant settlement, many tiny payouts and
                                       sponsored gas, measured and shown in the app
                                       and README

     Not built (roadmap)               Verified-steward applications, dispute bonds, fiat
                                       on- and off-ramps, high-frequency per-batch
                                       licensing
## Every flaw, solved inside the product
     Flaw                                 Product fix                                Where

     Contributors have no crypto          Phone or email login creates a wallet      Section 7
     wallets                              invisibly

     Contributors and voters have no      Signed actions submitted by a              Sections 7,
     MON for gas                          sponsoring relayer                         9

     "Why not a database?"                Escrow, payouts and licences anyone        Sections 2,
                                          can verify without trusting VaaniVault;    9
                                          public Verify page and agent check

     Copying after download               Fingerprinted bundles + leak-trace tool;   Section 11
                                          copying stays possible but is traceable

     Fake ownership or scraped data       Per-clip consent signatures, invite-only   Sections 7,
                                          contributors, admin pause                  11

     Consent withdrawal (DPDP Act         One-tap revocation on-chain; revoked       Section 11
     2023)                                clips excluded from future bundles and
                                          payouts

     Buyers need legal certainty          Generated licence agreement; its hash      Section 9
                                          is signed in the request and stored in
                                          the licence

     Fake or inactive councils            Invite-only council, one verified phone    Section 8
                                          per voter, quorum and auto-refund on
                                          expiry

     Lump-sum payouts hide who got        Per-contributor credits, visible on the    Section 10
     paid                                 receipt


     Flaw                                  Product fix                                 Where

     Not Monad-specific                    Features that need fast finality and tiny   Section 2
                                           fees, plus parallel-friendly contract
                                           design and measured results


  What no product can do, and the PRD states openly: stop a licensee from copying files, or
  prove a person's legal identity.
## 1. Product overview
  One-line pitch: VaaniVault lets a community decide who trains AI on its data, for what,
  and for how much, and pays every contributor the moment it says yes.
### Problem
       Invisible use. People who record voices, text or images rarely know who trains on their
       data or why.
       No collective voice. Communities that pool data, such as a language group, have no
       fair, transparent way to say yes or no.
       Contributors are left out. Payment, if any, goes to an intermediary; individual
       contributors cannot see what they earned.
       Crypto is a barrier. Existing on-chain data tools assume users have wallets and gas
       tokens; most contributors do not.
       Weak provenance. AI teams cannot easily prove the data they trained on was
       consented, licensed and paid for.
### Solution
     Problem                VaaniVault mechanism

     Invisible use          Every request states its purpose and signed
                            agreement; every decision is a public on-chain
                            event

     No collective voice    Invite-only community council votes with fixed,
                            published rules


     Problem                 VaaniVault mechanism

     Contributors left out   Each contributor is credited their share directly, in
                             the approval transaction

     Crypto barrier          Phone login with an invisible wallet; gas paid by the
                             platform

     Weak provenance         Manifest hash, consent root, agreement hash and
                             delivery fingerprint pinned to every licence
### Demo scenario
  A Tamil-speaking community in Chennai pools consented, clearly labelled demo voice
  clips from 6 contributors, who joined with their phone numbers. An AI lab requests a
  research licence for speech recognition, signs the generated agreement and deposits 1
  test MON into escrow. Two of three council members approve from their phones without
  holding any MON. In under a second, 0.7 MON is split among the 6 contributors by clip
  count, 0.2 goes to the community fund and 0.1 to the platform. The lab receives a non-
  transferable licence token and downloads a fingerprinted bundle; anyone can verify the
  licence on a public page.

  Tamil voice is the showcase; the contract licenses a hash, so the same flow serves text,
  images, video and tabular data.
## 2. Why Monad
  Any EVM chain could store VaaniVault's records; the product only works economically
  and feels usable on a chain with sub-second finality, tiny fees and EVM compatibility
  together, which is Monad.
### Three features that depend on Monad
   1. Pay every contributor directly. One approval credits many contributors a tiny amount
       each. On a chain where gas costs more than the payment, this design is impossible.
   2. Sponsored gas for every vote and consent. The platform pays gas for all community
       actions so nobody needs crypto. That is sustainable only when each action costs a tiny
       fraction of a MON.


   3. Instant settlement. The final vote, every payout and the licence mint land in one
      transaction with 300 ms blocks and 600 ms finality, so a voter sees the result
       immediately, like a normal app.
### Comparison
     VaaniVault needs        Ethereum        Ethereum L2s         Solana          Monad
                             mainnet

     Many tiny per-          Gas exceeds     Affordable           Affordable      Affordable
     contributor             payment
     payouts

     Instant, final result   ~12 s blocks,   Fast                 Fast            300 ms blocks,
     for voters              minutes to      confirmation; full                   600 ms finality
                             finality        finality tied to                     on its own
                                             Ethereum                             chain

     Platform-paid gas       Unaffordable    Affordable           Affordable      Affordable
     for all users

     Solidity,               Yes             Yes                  No (different   Yes, bytecode-
     OpenZeppelin,                                                language and    compatible
     Foundry,                                                     tools)
     MetaMask, viem

     Room for AI agents      No              Limited by           Yes             Yes, 10,000+
     checking and                            sequencer and                        TPS design
     buying licences at                      L1                                   capacity with
     volume                                                                       parallel
                                                                                  execution


  Among these options, only Monad meets all five needs at once.
### Built for parallel execution
  Monad executes transactions in parallel when they touch different storage. VaaniVault's
  contract is designed so that different communities never compete for the same storage
  slot:

       All state is keyed per dataset and per request; there is no global request counter (IDs
       are derived from dataset ID + per-dataset nonce).


       Licence token IDs equal request IDs, so minting touches no shared counter.
       Payouts credit per-address balances (pull payments), so payouts to different people
       never conflict.
       Relayer nonces are per signer, not global.
### Proving it: measurements for the submission
     Measurement                         How                               Where shown

     Gas per action (request, signed     forge test --gas-report and       README table
     vote, approval with 6 payouts,      testnet receipts
     withdraw)

     Cost in MON per action              Gas used × testnet gas price      README table,
                                         from receipts                     receipt page

     Time from final vote to licence     Client timer from vote            Receipt page:
     minted                              submission to confirmed receipt   "Settled in X s"

     Total sponsored gas for the demo    Sum of relayer transaction fees   Admin page and
     community                                                             README


  The README compares each measured action with the same gas at a typical Ethereum
  mainnet gas price, stated with its date and source.
### README paragraph (ready to use)
       Why Monad? VaaniVault pays every contributor directly, lets community members
       vote without holding crypto, and settles each licence instantly. That means many tiny
       transactions that must be final at once. On Ethereum, paying a contributor a few
       rupees costs more in gas than the payment. On Solana we would lose the Solidity and
       EVM tooling we build with. Monad gives us standard EVM contracts with 600 ms
       finality and low fees, so a community vote settles, pays every contributor and issues
       the licence in under a second. Our contract keeps each community's state separate,
       so Monad's parallel execution can process many communities at once.
### Roadmap headline: high-frequency licensing
  Monad describes itself as built for high-frequency finance; VaaniVault's next step is a
  high-frequency data economy. AI agents would pay per batch of data as they use it, each
  payment settling in about 300 ms and split among contributors instantly. Per-use licensing
  like this needs exactly the throughput and finality Monad provides.
## 3. Goals, non-goals and success criteria
  The hackathon goal is one flawless community licence flow on Monad testnet, where a
  non-crypto contributor and voter never see a seed phrase or need MON.
### Goals
   1. Complete licence lifecycle on Monad testnet: consent, register, request with escrow,
      gasless vote, settle, deliver, verify.
   2. Pay each contributor directly and show it on the receipt.
   3. Contributors and voters use phone or email login and never pay gas.
   4. Every decision, payment and licence is checkable on a block explorer and on a public
      Verify page.
   5. Prove the Monad advantage with measured gas and settlement time.
   6. Keep raw data and personal information off-chain.
### Non-goals for the hackathon
       Legal enforceability or verified legal identity.
       Preventing copying after download (tracing is in scope; prevention is not).
       Real-money payments, fiat ramps or mainnet deployment.
       Large-scale storage, data quality scoring or model training.
### Success criteria
     Metric                              Target

     End-to-end demo                     Under 3 minutes, no manual workarounds

     Settlement time                     Final vote to licence minted in under 2 s, shown in
                                         the app


     Metric                                 Target

     Contributor and voter gas spent        0 MON (all sponsored)

     Payout accuracy                        Sum of credits equals escrow exactly, every
                                            contributor credited

     Failure handling                       Rejected, cancelled and expired requests refund
                                            100% of escrow

     Leak trace                             A fingerprinted bundle is matched to the correct
                                            licensee

     Contract tests                         All cases in Section 16 pass

     Privacy                                Zero personal data or raw files on-chain

     Submission                             Live demo URL, video, write-up, public repo and
                                            verified contracts by 13 Oct 2026
## 4. Users, roles and permissions
  Roles are per dataset, not per account; contributors and voters use phone login and
  signed messages, while buyers and admins use regular wallets.


     Role               Who                      Login                     Main jobs

     Steward            Organiser acting for     Phone/email or            Invite contributors and
                        a community              wallet                    council, register dataset, set
                                                                           terms

     Contributor        Person who               Phone/email               Upload clips, sign consent,
                        recorded the data        (embedded wallet)         withdraw earnings, revoke
                                                                           consent

     Council voter      Invited community        Phone/email               Vote Approve, Reject or
                        member                   (embedded wallet)         Abstain, gaslessly

     Individual         Single creator           Wallet                    Register own dataset,
     owner              (secondary path)                                   approve or reject requests

     Requester          AI lab, researcher or    Wallet or agent key       Browse, sign agreement, pay
                        AI agent                                           escrow, download


     Role                Who                      Login                    Main jobs

     Relayer             VaaniVault service       Server key               Submit signed votes and
                         wallet                                            consent changes; pays gas;
                                                                           cannot forge signatures

     Delivery            VaaniVault server        Server key               Build bundles, record
     service                                                               delivery fingerprint

     Admin               Platform operator        Wallet                   Pause listings, view
                                                                           moderation log, top up
                                                                           relayer

     Public              Anyone, including        None                     Check licences, consent
     verifier            agents                                            and payouts
### Permissions matrix
    Action                Steward   Contributor   Voter        Requester Relayer    Admin           Anyone

    Register              Yes       No            No           No        No         No              No
    community
    dataset

    Sign consent /        No        Yes (own      No           No        Submits    No              No
    revoke consent                  clips)                               only

    Request licence +     No        No            No           Yes       No         No              No
    escrow

    Vote                  No        No            Yes          No        Submits    No              No
                                                  (signed)               only

    Cancel own            No        No            No           Yes       No         No              No
    pending request

    Finalize after        Yes       Yes           Yes          Yes       Yes        Yes             Yes
    deadline

    Withdraw earnings     Fund      Yes           No           Refunds   No         Platform fee    No
                          only

    Record delivery       No        No            No           No        No         Delivery        No
    fingerprint                                                                     service only

    Pause listing (new    No        No            No           No        No         Yes             No
    requests only)

    Verify licence        Yes       Yes           Yes          Yes       Yes        Yes             Yes


  The relayer only forwards messages that users signed; the contract checks every
  signature, so a compromised relayer cannot cast votes or revoke consent on anyone's
  behalf. Admin pause never alters votes, payments or licences already recorded.
## 5. End-to-end workflow
  The workflow runs in three phases: the community sets up data and consent once, each
  licence request waits in escrow for a council decision, and approval triggers payment,
  delivery and ongoing rights in one chain of events.


  end-to-end workflow · 10 stages in 3 phases

  Only stage 7 moves escrow to the community; every other ending of stage 6 returns it to
  the requester. Stages 1, 2, 6 and 10 need no crypto knowledge or gas from contributors and
  voters (Section 7); stage 7 is where Monad's sub-second finality shows (Section 2).
## 6. Functional requirements
  Must is the demo and is built first; Should items are built in the listed tier order once Must
  passes end to end; Could is pitched as roadmap unless time remains.


     ID             Module           Requirement                                      Tier

     FR-01          Wallet           Connect MetaMask, auto-switch to Monad           Must
                                     testnet (chain 10143)

     FR-            Marketplace      Catalogue: category, language, size, price,      Must
     02                              consent count, contributors,
                                     Community/Individual badge

     FR-            Marketplace      Search; filter by category, purpose, ownership   Must
     03                              type; 6 seeded datasets across categories

     FR-            Dataset detail   Synthetic sample player, terms, purposes,        Must
     04                              split bar, contributor list (short addresses),
                                     manifest hash, council

     FR-            Contribute       Contributor uploads clips; server hashes each    Must
     05                              file and links it to the contributor

     FR-            Consent          Contributor signs EIP-712 consent (dataset,      Must
     06                              purposes, share); server builds consent
                                     Merkle root

     FR-            Register         Steward sets metadata, terms, council (3),       Must
     07                              threshold, quorum, voting period, split,
                                     contributor weights

     FR-            Request          Requester picks purpose, writes intended         Must
     08                              use, reviews generated agreement, pays
                                     escrow; agreement and use hashes stored

     FR-            Voting           Voter signs vote (EIP-712); relayer submits      Must
     09                              castVoteBySig ; voter pays no gas

     FR-10          Voting           Auto-finalize when decided; anyone can           Must
                                     finalize after deadline

     FR-11          Settlement       Approval credits each contributor pro rata,      Must
                                     community fund and platform, and mints
                                     licence, in one transaction


     ID             Module            Requirement                                       Tier

     FR-12          Refunds           Reject, cancel and expiry refund escrow in full   Must

     FR-13          Withdraw          Any credited address withdraws its balance        Must
                                      (pull payment); embedded-wallet users
                                      withdraw via relayer-sponsored signed
                                      request

     FR-14          Licence           Soulbound licence token with dataset,             Must
                                      purpose, expiry, manifest, agreement and
                                      terms hashes

     FR-15          Licence           Public isLicensed(datasetId, holder,              Must
                                      purpose) view

     FR-16          Access            Download gate: wallet signs a challenge;          Must
                                      server checks isLicensed before serving a
                                      short-lived link

     FR-17          Receipt           Timeline, per-recipient payouts, "Settled in X    Must
                                      s", gas used, tx links

     FR-18          Individual path   Owner approves or rejects directly                Must
                                      (secondary path and fallback)

     FR-19          Login (Tier 1)    Phone or email login with Privy embedded          Should
                                      wallets for contributors, voters and stewards

     FR-            Consent (Tier     One-tap consent revocation via signed             Should
     20             2)                message; on-chain flag; revoked clips and
                                      weights excluded from future bundles and
                                      payouts

     FR-21          Delivery (Tier    Per-licensee bundle with unique canary clips;     Should
                    3)                fingerprint hash recorded on-chain once

     FR-            Trace (Tier 3)    Leak-trace page: upload suspect files, match      Should
     22                               canaries to a licence

     FR-            Verify (Tier 4)   Public Verify page: dataset + address →           Should
     23                               licence status, terms, payouts

     FR-            Admin (Tier 4)    Pause listing; relayer balance and sponsored-     Should
     24                               gas totals; moderation log


     ID             Module      Requirement                                     Tier

     FR-            Agents      Script showing an AI agent checking             Could
     25                         isLicensed and requesting a licence

     FR-            Disputes    Bonded disputes that freeze new licences        Could
     26                                                                         (roadmap)

     FR-            Stewards    Verified-steward application and badge          Could
     27                                                                         (roadmap)

     FR-            Payments    Fiat on- and off-ramps; stablecoin pricing      Could
     28                                                                         (roadmap)

     FR-            Licensing   Per-batch high-frequency licensing for agents   Could
     29                                                                         (roadmap)
### Transaction UX rules (every write)
       Show awaiting signature, submitting, confirmed with explorer link; for relayed actions,
       signed, relaying, confirmed.
       On revert or rejected signature, show the decoded reason and leave the UI unchanged;
       never show success before a receipt.
       Disable the action while pending; show remaining relayer budget to admins only.
## 7. Identity, onboarding and gasless actions
  Contributors and voters log in with a phone number or email, get an invisible wallet, and
  only ever sign messages; a relayer pays the gas, and the contract verifies every signature.
### Onboarding by invite
   1. The steward creates the community and generates invite links for contributors and
      council members.
   2. The invitee opens the link and logs in with phone OTP or email (Privy). Privy creates an
      embedded wallet; the user never sees a seed phrase or the word "wallet".
   3. The server binds the invite to that wallet address and to the role (contributor or voter).
      One verified phone number maps to one account.
   4. Council membership is fixed on-chain when the steward registers the dataset; new
      members apply only to future requests.


  Fallback: if Privy integration is not finished, invitees connect MetaMask; signing and
  gasless relaying work the same way.
### Gasless actions
     Action         User signs (EIP-712 typed   Relayer calls               Contract checks
                    data)

     Consent        Consent(datasetId,          none (root posted by        Merkle root of
                    contributor,                steward at registration)    signed consents
                    purposeMask, weight,
                    nonce)

     Vote           Vote(requestId, voter,      castVoteBySig               Signer is in the
                    choice, nonce,                                          request's council
                    deadline)                                               snapshot; nonce
                                                                            unused; not
                                                                            expired

     Revoke         Revoke(datasetId,           revokeConsentBySig          Signer is a
     consent        contributor, nonce,                                     contributor of the
                    deadline)                                               dataset

     Withdraw       Withdraw(account,           withdrawBySig               Funds always go to
                    nonce, deadline)                                        the signer, never
                                                                            to the relayer


  Relayer rules
       A single funded server wallet with a rate limit per account (for example 20 actions per
       hour) and a daily budget.
       It forwards only the user's exact signed payload; it cannot change the vote, recipient or
       dataset.
       Per-signer nonces stop replay; deadlines stop stale signatures.
       If the relayer is down, the same signed message can be submitted by anyone, including
       the user from a wallet, so it never becomes a single point of failure for votes.


  What this proves and what it does not
  Phone login proves control of a phone number and the wallet behind it. It does not prove
  legal identity or that the person truly recorded the clips. The steward's invite is the trust
  anchor, and that is shown on the dataset page ("Contributors invited by steward X").


  8. Community governance rules
  A community request is approved only when at least threshold council members sign
  Approve before the deadline; every other ending refunds the requester automatically.


  Rule set (fixed at registration)

     Parameter         Demo value                       Rule

     Council           3 invited members                Invite-only, one verified phone per
                                                        member; changes apply to future
                                                        requests only

     Snapshot          Per request                      Each request stores the council version
                                                        at creation

     Approval          2 Approve votes                  Absolute count, not a share of votes
     threshold                                          cast

     Quorum            2 votes cast                     Approve, Reject and Abstain all count

     Voting period     10 minutes (demo), 72 hours      Starts at request creation
                       (default)

     Vote options      Approve, Reject, Abstain         Signed, gasless, one per member per
                                                        request, final

     Conflict rule     Requester cannot vote            Enforced on-chain

     Council size      Up to 15                         Keeps tally checks cheap


  Outcome logic
   1. Early approve: when Approve votes reach the threshold, the same transaction settles
      payouts and mints the licence.


   2. Early reject: when Approve votes plus members yet to vote can no longer reach the
      threshold, the request is rejected and refunded.
   3. Deadline, quorum met, threshold not met: rejected and refunded.
   4. Deadline, quorum not met: expired and refunded.
   5. Ties cannot block an outcome because approval needs an absolute count.
   6. Finalization: anyone may call finalize() after the deadline; the UI shows a Finalize
       button and the relayer finalizes automatically.


  Worked examples (council 3, threshold 2)

     Votes cast                  Result       When

     Approve, Approve            Approved     On the 2nd vote

     Reject, Reject              Rejected     On the 2nd vote

     Approve, Reject, Approve    Approved     On the 3rd vote

     Approve, Abstain, Reject    Rejected     On the 3rd vote

     Approve only                Expired      At deadline

     None                        Expired      At deadline


  Voter experience
       The voter gets a link (SMS or chat) to a mobile-friendly vote card: dataset, requester,
       purpose, intended use, price and their own expected share.
       Optional Tamil labels on the card.
       One tap signs the vote; the card shows the live tally and "Settled" with the payout as
       soon as the outcome is decided.

  Individual datasets skip voting: the owner approves or rejects, and an unanswered
  request expires and refunds at the deadline.
## 9. Smart contract design
  Two contracts: VaaniVault.sol (registry, consent, requests, signed voting, escrow,
  payouts) and VaaniLicence.sol (soulbound ERC-721 that only VaaniVault can mint),
  built on OpenZeppelin 5 with EIP-712 signatures.


  Data structures

     enum Ownership { Individual, Community }
     enum Purpose { Research, CommercialTraining, Evaluation, FineTuning }
     enum Status { Pending, Approved, Rejected, Cancelled, Expired }
     enum Choice { None, Approve, Reject, Abstain }


     struct Dataset {
         address steward;                // owner or community steward
             Ownership ownership;
             bytes32 manifestHash;       // Merkle root of file hashes
             bytes32 consentRoot;        // Merkle root of signed consents
             string metadataURI;         // off-chain JSON
             uint256 price;              // wei of MON
             uint64   licenceDuration;   // seconds
             uint8    purposeMask;       // allowed purposes as bit flags
             uint16   contributorsBps;   // e.g. 7000
             uint16   communityBps;      // e.g. 2000
             uint16   platformBps;       // e.g. 1000 (sum = 10000)
             address communityFund;
             uint8   threshold; uint8 quorum; uint32 votingPeriod;
             uint32   councilVersion;
             uint64   requestNonce;      // per-dataset, no global counter
             uint32   activeWeight;      // sum of weights of non-revoked contributors
             bool     paused;
     }


     struct Request {
         uint256 datasetId;
             address requester;
             Purpose purpose;
             bytes32 useHash;            // intended-use text, stored off-chain
             bytes32 agreementHash;      // generated licence agreement the requester
     signed by sending the tx
             bytes32 termsHash;          // snapshot of price, split, duration,
     manifest
         uint256 escrow;
             uint64   deadline;
             uint32   councilVersion;
             uint8    approvals; uint8 rejections; uint8 abstains;
             Status   status;
             uint64   expiresAt;         // licence expiry once approved
             bytes32 deliveryFingerprint; // canary set hash, written once


     }

     mapping(uint256 => address[]) contributors;                    // per dataset,
     capped at 50 in v1
     mapping(uint256 => mapping(address => uint32)) weight;         // clip count
     mapping(uint256 => mapping(address => bool)) revoked;
     mapping(address => uint256) balances;                          // pull payments
     mapping(address => uint256) nonces;                            // per signer


  Request IDs are keccak256(datasetId, requestNonce) ; licence token ID = request ID.
  No storage is shared between datasets.


  Functions

     Function                              Caller          What it does

      registerDataset(params,              Steward /       Validates bps sum, council
     contributors, weights, council)       owner           size, threshold ≤ council, ≤ 50
                                                           contributors; stores dataset

      updateTerms(datasetId, price,        Steward         Future requests only
     duration, purposeMask)

      requestLicence(datasetId, purpose,   Requester       Requires exact price, allowed
     useHash, agreementHash) payable                       purpose, not paused;
                                                           snapshots terms and council

      castVoteBySig(requestId, voter,      Relayer or      Verifies EIP-712 signature and
     choice, deadline, sig)                anyone          council membership; auto-
                                                           finalizes

      castVote(requestId, choice)          Council         Same, direct from wallet
                                           member          (fallback)

      decide(requestId, approve)           Individual      Approve settles + mints;
                                           owner           reject refunds

      finalize(requestId)                  Anyone          After deadline: applies
                                                           Section 8 outcome logic

      cancel(requestId)                    Requester       Pending only; full refund

      revokeConsentBySig(datasetId,        Relayer or      Marks revoked; removes
     contributor, deadline, sig)           anyone          weight from future payouts


     Function                                Caller           What it does

      withdraw() / withdrawBySig(account,    Account /        Sends the account's balance
     deadline, sig)                          relayer          to the account

      recordDelivery(requestId,              Delivery         Writes canary fingerprint
     fingerprint)                            service role     once, for approved requests
                                                              only

      setPaused(datasetId, bool)             Admin            Blocks new requests only

      isLicensed(datasetId, holder,          Anyone           True if approved and
     purpose) view                                            unexpired

      licenceOf(requestId) view              Anyone           Returns all hashes, status,
                                                              expiry, payouts


  Settlement maths

     \text{contributorPool} = \text{escrow} \times \frac{\text{contributorsBps}}
     {10000}, \qquad \text{share}_i = \text{contributorPool} \times \frac{w_i}
     {\sum_{j \notin \text{revoked}} w_j}


  Platform share = escrow × platformBps / 10,000. The community fund receives escrow
  minus everything else, which absorbs all rounding, so credits always sum exactly to the
  escrow.


  Events (public audit trail)
   DatasetRegistered , TermsUpdated , LicenceRequested , VoteCast , RequestApproved ,
   RequestRejected , RequestExpired , RequestCancelled , PaymentCredited(requestId,
  recipient, amount) , Withdrawn , ConsentRevoked , LicenceMinted ,
   DeliveryRecorded , DatasetPaused .


  Contract rules
       Checks-effects-interactions everywhere; ReentrancyGuard on every function that
       sends MON.
       Custom errors ( InvalidSplit , WrongPayment , PurposeNotAllowed , Paused ,
        NotCouncil , AlreadyVoted , BadSignature , SignatureExpired , NotPending ,
        DeadlineNotReached , AlreadyDelivered ) for clear UI messages.


       Roles via AccessControl : ADMIN_ROLE (pause only), DELIVERY_ROLE (record
       fingerprint only). No role can move escrow or edit votes, licences or payouts.
       Licence token: ERC-721 with transfers reverted and ERC-5192 locked() returning
       true.
       Tooling: Foundry for tests, fuzzing of settlement maths, deployment and source
       verification on the testnet explorer.


  10. Payments and per-contributor revenue split
  The requester's payment sits in escrow until the decision; approval credits every
  contributor, the community fund and the platform in the same transaction, and any other
  ending refunds the requester in full.


  Money lifecycle
   1. Request: requester sends exactly the listed price in testnet MON; the contract holds
       it.
   2. Approve: the approving vote (or owner decision) credits every recipient's balance and
      mints the licence.
   3. Reject, cancel or expire: the full escrow is credited back to the requester.
   4. Withdraw: recipients withdraw any time; embedded-wallet users sign a gasless
      withdrawal and the funds go to their own address.


  Demo split for 1 test MON

     Recipient             Rule                             Amount

     Contributor A         12 of 40 clips                   0.21 MON

     Contributor B         8 of 40 clips                    0.14 MON

     Contributor C         6 of 40 clips                    0.105 MON

     Contributor D         6 of 40 clips                    0.105 MON

     Contributor E         4 of 40 clips                    0.07 MON

     Contributor F         4 of 40 clips                    0.07 MON

     Contributors total    7,000 bps                        0.7 MON


     Recipient             Rule                              Amount

     Community fund        2,000 bps + rounding remainder    0.2 MON

     Platform operations   1,000 bps                         0.1 MON

     Total                 10,000 bps                        1 MON


  Percentages are illustrative; each community sets its own split at registration, and the
  platform fee is shown on every listing.


  Rules
       Splits and contributor weights are snapshotted into the request's terms hash; later
       changes never affect an open request.
       A contributor who revoked consent before settlement receives nothing from that
       settlement; their weight is removed from the denominator.
       v1 caps a dataset at 50 contributors so one settlement stays well within gas limits;
       larger communities move to a Merkle distributor (roadmap).
       Every amount in the UI is labelled "testnet MON, no real value".


  Receipt contents
  Dataset and request IDs, requester, purpose, licence token ID, start and expiry, manifest,
  terms and agreement hashes, delivery fingerprint, every recipient and amount, gas used,
  "Settled in X s", and links to the request, each vote, the settlement and the delivery
  transactions.


  11. Data, consent, provenance and leak tracing
  Only hashes, addresses, amounts and statuses go on-chain; every clip is tied to a signed
  consent, every delivery is fingerprinted to its licensee, and revoked consent is honoured
  in all future deliveries and payouts.


  What lives where

     Item                          On-chain              Off-chain

     Clips and other files         No                    Private storage, served only through
                                                         the download gate

     Synthetic sample preview      No                    Public folder

     Name, description,            URI only              Metadata JSON + SQLite
     category, language

     Manifest (per-file SHA-256)   Merkle root           Full list, clip → contributor mapping

     Consent signatures            Merkle root +         Signed messages with timestamp
                                   revoked flags

     Intended use and licence      Hashes                Text and generated PDF
     agreement

     Delivery canaries             Fingerprint hash      Canary pool and licence
                                                         assignments

     Votes, payouts, licences      Yes                   Indexed cache for the dashboard

     Phone numbers, emails,        Never                 Held by the login provider; app
     names                                               stores wallet address only


  Consent, per clip
   1. A contributor uploads clips; the server hashes each file and records it against the
      contributor's wallet.
   2. The contributor signs one EIP-712 consent covering their clips, allowed purposes and
       revenue share.
   3. At registration, the consent Merkle root and each contributor's weight (clip count) go
      on-chain.
   4. The dataset page shows consenting contributors and lets any contributor verify their
      signature is included in the root.


  Consent withdrawal (DPDP Act 2023)
   1. The contributor taps Withdraw consent and signs; the relayer calls
      revokeConsentBySig .


   2. The contract marks them revoked and removes their weight from future settlements.
   3. The server excludes their clips from every bundle built afterwards; the dataset page
      updates its consent count.
   4. Licences already issued run until expiry; this rule is shown to contributors before they
       consent.

  No personal data ever reaches the chain, so withdrawal never conflicts with an immutable
  record.


  Provenance pinning
       The manifest root is stored with the dataset and copied into each request's terms
       hash.
       After download, the licensee can re-hash files to prove they received exactly the
       licensed version.
       Changing files requires a new manifest; old licences still point to the old one.


  Fingerprinted delivery and leak tracing
   1. The server keeps a pool of canary clips: short synthetic recordings of unique random
      phrases (for example "seven blue river forty-two").
   2. Each licence's bundle includes 5 canaries unique to that licence, mixed among real
       clips under ordinary file names.
   3. The server writes the fingerprint (hash of the licence's sorted canary hashes) on-chain
      with recordDelivery , once.
   4. On the leak-trace page, anyone uploads suspect files; exact hash matches identify the
      licence, and the on-chain fingerprint proves the assignment existed before the leak.

  Limits, stated in the product: v1 matches exact files, so re-encoded audio needs v2
  matching by transcribing canary phrases; a determined leaker who finds and removes
  canaries can evade tracing. Tracing deters and attributes leaks; it does not prevent
  copying.


  Licence-gated download
   1. The requester clicks Download and signs a gas-free challenge.
   2. The server recovers the address and calls isLicensed(datasetId, address,
       purpose) on Monad.


   3. If true, it builds or reuses the fingerprinted bundle and returns a 10-minute signed link;
      if false, it returns a clear 403 reason.
   4. Every download is logged against the licence.


  Demo data policy
  Only synthetic or team-recorded clips with written consent from each speaker, clearly
  labelled; no scraped or third-party audio.


  13. UI pages
  Eight Must pages (one of them static) carry the demo, with the mobile vote card and the
  receipt as the two screens that sell it.


     #          Page                 Key elements                                     Tier

     1          Marketplace          Search, category chips, cards with price,        Must
                                     consent count, contributor count,
                                     Community badge

     2          Dataset detail       Sample player, terms, purposes, split bar with   Must
                                     per-contributor shares, manifest hash,
                                     council, Request button

     3          Request flow         Purpose, intended use, generated agreement       Must
                                     preview, price, pay into escrow

     4          Vote card (mobile-   Request summary, voter's expected share,         Must
                first)               Approve / Reject / Abstain, live tally,
                                     countdown, "Settled" state

     5          Receipt              Timeline (Requested → Votes → Settled →          Must
                                     Minted → Delivered), "Settled in X s", gas
                                     used, payout table, tx links, Download

     6          Community setup      Invite contributors and council, upload and      Must
                                     hash clips, consent status, terms, split,
                                     register

     7          My earnings          Balance per dataset, Withdraw (gasless),         Must
                                     Withdraw consent


     #          Page                     Key elements                                      Tier

     8          Verify a licence         Public: dataset + address → status, terms,        Should
                                         hashes, payouts

     9          Leak trace               Upload suspect files → matched licence or no      Should
                                         match

     10         Admin                    Pause listing, relayer balance, total sponsored   Should
                                         gas, moderation log

     11         About and limits         What the chain proves and what it does not,       Must
                                         in plain words                                    (static)


  Design direction
          Sidebar layout on desktop, bottom tabs on mobile for contributors and voters.
          No crypto words on contributor and voter screens: "Sign in", "Approve", "Your
          earnings", never "wallet", "gas" or "transaction".
          Requester and admin screens show the full on-chain detail: network pill, copyable
          hashes, explorer links.
          Every amount labelled "testnet MON".
          Tamil labels optional on vote card and earnings page.
          Accessible contrast, visible focus states, and large tap targets on mobile.


  14. Security, privacy and stated limitations
  The design removes every way to take money or data without the agreed decision; what
  remains are honest limits that the product states openly.


  Non-functional requirements

     Area                Requirement

     Security            Tests for every revert and signature path; no keys
                         in the repo ( .env + .gitignore ); relayer key only
                         on the server

     Reliability         UI waits for receipts; relayed actions show their
                         own states; failed actions show the decoded error


     Area            Requirement

     Availability    Signed votes can be submitted by anyone if the
                     relayer is down; relayer auto-finalizes expired
                     requests

     Performance     Marketplace under 2 s with seeded data;
                     dashboard reads an event cache, not repeated RPC
                     calls

     RPC limits      Public testnet RPC is rate-limited (about 20–25
                     requests per second); use a sponsor RPC key
                     (QuickNode or Alchemy) for the backend

     Privacy         No personal data on-chain; phone numbers stay
                     with the login provider

     Usability       A first-time voter can vote in under 30 seconds
                     from the invite link

     Scalability     Storage swappable (local → S3 or IPFS) without
                     contract changes; per-dataset state for parallel
                     execution


  Threat model

     Threat                      Mitigation                             Residual risk

     Requester takes data        Escrow first; download gate            None on the gated path
     without paying              checks the chain

     Steward takes money         Funds go to contributors and           Off-chain delivery still
     without delivering          fund only on approval; manifest        trusted
                                 pinned

     Relayer forges or alters    Contract verifies EIP-712              None
     votes                       signatures and nonces

     Relayer drained by spam     Per-account rate limits, invite-       Service slowdown only
                                 only accounts, daily budget

     Signature replay            Per-signer nonces, deadlines,          None
                                 domain separator with chain ID
                                 10143


     Threat                    Mitigation                         Residual risk

     Reentrancy in payouts     Pull payments,                     Low
                                ReentrancyGuard , checks-
                               effects-interactions

     Fake contributors or      Invite-only, per-clip consent,     Steward can still lie; identity
     scraped data              admin pause                        not legally verified

     Fake council members      Invite-only, one verified phone    A dishonest steward could
                               per member                         invite people they control

     Licensee leaks data       Fingerprinted bundles and leak     Copying cannot be
                               trace                              prevented; canaries can be
                                                                  removed

     Leaked download link      10-minute links bound to the       Short window
                               licensee

     Admin abuse               Admin can only pause new           Unfair pause is visible but
                               requests; all actions are events   possible


  Stated limitations (About page, README and video)
       Ownership and contributor identity are declared through the steward's invites, not
       legally verified.
       Consent signatures prove the account holder agreed, not that consent was fully
       informed.
       Licences and fingerprints trace misuse; they do not stop copying.
       Testnet MON has no value; this is not a commercial payment system.


  16. Testing and acceptance criteria
  The build is ready when every Must test passes on a fresh Monad testnet deployment and
  the full demo runs without manual fixes.


  Contract tests (Foundry)

     ID         Scenario                                 Expected

     T-01       Register with bps not summing to         Reverts InvalidSplit
                10,000

     T-         Register with 51 contributors            Reverts

     T-         Request with wrong msg.value             Reverts WrongPayment

     T-         Request disallowed purpose or paused     Reverts
     04         dataset

     T-         Two signed Approve votes via relayer     Approved on 2nd vote; 6 contributors,
     05                                                  fund and platform credited; licence
                                                         minted

     T-         Per-contributor amounts for weights      Match Section 10 exactly; total equals
     06         12/8/6/6/4/4                             escrow

     T-07       Fuzz: random escrow and weights          Credits always sum to escrow

     T-         Approve, Abstain, Reject                 Rejected on 3rd vote; refunded

     T-         One vote then deadline, finalize()       Expired; refunded

     T-10       Replayed vote signature                  Reverts BadSignature (nonce used)

     T-11       Signature from non-council address       Reverts NotCouncil

     T-12       Expired signature deadline               Reverts SignatureExpired

     T-13       Council changed during a vote            Open request uses its snapshot

     T-14       Contributor revokes before settlement    Gets nothing; others' shares rise
                                                         proportionally

     T-15           withdrawBySig submitted by relayer   Funds go to signer, not relayer

     T-16       Malicious recipient re-enters withdraw   Reverts; balances unchanged

     T-17       Licence token transfer                   Reverts (soulbound)


     ID         Scenario                              Expected

     T-18           isLicensed after expiry           False

     T-19           recordDelivery twice or by non-   Reverts
                delivery role

     T-         Requester cancels pending request     Refunded; later votes revert

     T-21       Individual owner approve and reject   Same settlement and refund behaviour


  End-to-end acceptance on Monad testnet
       Steward invites 6 contributors and 3 voters; each joins by phone or email (or MetaMask
       fallback).
       Contributors upload clips and sign consent; dataset registers with manifest and
       consent roots.
       Requester pays escrow and signs the generated agreement; hashes visible on the
       receipt.
       Two voters approve from a phone with zero MON; the receipt shows "Settled in X s"
       and 8 payout lines.
       A contributor withdraws earnings without holding MON.
       Licensed wallet downloads a fingerprinted bundle; unlicensed wallet gets a clear
       refusal.
       Leak-trace page matches a canary file from the bundle to the correct licence.
       A contributor revokes consent; the next bundle excludes their clips and the next
       settlement excludes them.
       Rejected and expired requests refund the requester in full.
       No reverted or unsigned action ever shows success.
       Contracts verified on the explorer; README contains measured gas and settlement
       times.


  17. Demo script, submission write-up and roadmap
  Because judging is online, the video and README must answer every question a judge
  would ask, without anyone there to explain.


  Demo video (3 minutes)
   1. Hook (15 s): "AI models learn Indian languages from voices that were never asked.
      VaaniVault lets a community decide, and pays every contributor the moment it says
       yes."
   2. Community (25 s): a contributor joins with a phone number, records clips and signs
      consent; no wallet or crypto shown.
   3. Marketplace (15 s): several categories; open the Tamil voice dataset with 6
       contributors and its consent count.
   4. Request (25 s): the AI lab picks Research, reviews the generated agreement and pays 1
       test MON into escrow.
   5. Vote (30 s): two council members approve on phones holding zero MON; the second
      vote settles instantly.
   6. Receipt (25 s): "Settled in X s", 8 payout lines, gas used, licence token, explorer links.
   7. Delivery and trace (25 s): licensed download succeeds, unlicensed is refused; leak
       trace matches a canary to the licence.
   8. Why Monad and limits (20 s): the measured table; one sentence on what the chain
       does not prove.

  Record the run on the live testnet deployment; keep a second take as backup.


  Write-up structure (project profile and README)
   1. Problem and who it serves (Tamil community story).
   2. How it works (workflow diagram from Section 5).
   3. Every flaw and its in-product fix (the table from At a glance).
   4. Why Monad, with measured gas and settlement times (Section 2).
   5. Contracts: addresses, verified source links, test summary.
   6. Limitations, stated plainly.
   7. Roadmap.
   8. How to run it locally; demo accounts.


  Roadmap
   1. High-frequency licensing: AI agents pay per data batch, settled and split in about 300
      ms each.
   2. Merkle distributor for communities with thousands of contributors.


   3. Verified-steward applications and bonded disputes that freeze new licences.
   4. Fiat on- and off-ramps so buyers pay by card or invoice and contributors cash out in
       rupees.
   5. Canary matching that survives re-encoding, and checks for canary phrases in model
       outputs.
   6. Agent identity and reputation (ERC-8004) for AI agents that hold licences.
   7. More languages and communities, starting with other Indian languages.


  Final pitch line
  VaaniVault gives communities a verifiable way to decide who trains on their data, for
  what, and for how much, and pays every contributor in under a second on Monad.


  Sources
       Metropolis hackathon page: tracks, deadline (13 Oct 2026), submission requirements,
       sponsor list.
       Monad current facts: chain ID 10143, RPC, faucet, 300 ms block time, 600 ms finality,
       throughput.
       Monad testnet network information: RPC providers, rate limits, explorers.
