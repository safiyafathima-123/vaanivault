// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {EIP712} from "@openzeppelin/contracts/utils/cryptography/EIP712.sol";
import {ECDSA} from "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import {AccessControl} from "@openzeppelin/contracts/access/AccessControl.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {VaaniLicence} from "./VaaniLicence.sol";

/**
 * @title VaaniVault
 * @notice Data vault for community and individual data licensing, governance, and payouts on Monad.
 */
contract VaaniVault is EIP712, AccessControl, ReentrancyGuard {
    using ECDSA for bytes32;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant DELIVERY_ROLE = keccak256("DELIVERY_ROLE");

    bytes32 public constant VOTE_TYPEHASH =
        keccak256("Vote(uint256 requestId,address voter,uint8 choice,uint256 nonce,uint256 deadline)");
    bytes32 public constant REVOKE_TYPEHASH =
        keccak256("Revoke(uint256 datasetId,address contributor,uint256 nonce,uint256 deadline)");
    bytes32 public constant WITHDRAW_TYPEHASH =
        keccak256("Withdraw(address account,uint256 nonce,uint256 deadline)");

    enum Ownership {
        Individual,
        Community
    }
    enum Purpose {
        Research,
        CommercialTraining,
        Evaluation,
        FineTuning
    }
    enum Status {
        Pending,
        Approved,
        Rejected,
        Cancelled,
        Expired
    }
    enum Choice {
        None,
        Approve,
        Reject,
        Abstain
    }

    struct Dataset {
        address steward;
        Ownership ownership;
        bytes32 manifestHash;
        bytes32 consentRoot;
        string metadataURI;
        uint256 price;
        uint64 licenceDuration;
        uint8 purposeMask;
        uint16 contributorsBps;
        uint16 communityBps;
        uint16 platformBps;
        address communityFund;
        uint8 threshold;
        uint8 quorum;
        uint32 votingPeriod;
        uint32 councilVersion;
        uint64 requestNonce;
        uint32 activeWeight;
        bool paused;
    }

    struct Request {
        uint256 datasetId;
        address requester;
        Purpose purpose;
        bytes32 useHash;
        bytes32 agreementHash;
        bytes32 termsHash;
        uint256 escrow;
        uint64 deadline;
        uint32 councilVersion;
        uint8 approvals;
        uint8 rejections;
        uint8 abstains;
        Status status;
        uint64 expiresAt;
        bytes32 deliveryFingerprint;
    }

    struct RegisterParams {
        Ownership ownership;
        bytes32 manifestHash;
        bytes32 consentRoot;
        string metadataURI;
        uint256 price;
        uint64 licenceDuration;
        uint8 purposeMask;
        uint16 contributorsBps;
        uint16 communityBps;
        uint16 platformBps;
        address communityFund;
        uint8 threshold;
        uint8 quorum;
        uint32 votingPeriod;
    }

    VaaniLicence public immutable licenceContract;
    address public immutable platformTreasury;

    mapping(uint256 => Dataset) internal _datasets;
    mapping(uint256 => Request) internal _requests;

    mapping(uint256 => address[]) internal _contributors;
    mapping(uint256 => mapping(address => uint32)) public weight;
    mapping(uint256 => mapping(address => bool)) public revoked;

    mapping(uint256 => mapping(uint32 => address[])) internal _councils;
    mapping(uint256 => mapping(uint32 => mapping(address => bool))) internal _isCouncil;

    mapping(uint256 => mapping(address => Choice)) internal _votes;
    mapping(uint256 => mapping(address => mapping(Purpose => uint256))) internal _latestLicence;

    mapping(address => uint256) public balances;
    mapping(address => uint256) public nonces;

    // Custom errors
    error InvalidSplit();
    error WrongPayment();
    error PurposeNotAllowed();
    error Paused();
    error NotCouncil();
    error AlreadyVoted();
    error BadSignature();
    error SignatureExpired();
    error NotPending();
    error DeadlineNotReached();
    error DeadlinePassed();
    error AlreadyDelivered();
    error DatasetExists();
    error DatasetNotFound();
    error NotSteward();
    error NotRequester();
    error NotIndividual();
    error NotCommunity();
    error InvalidCouncil();
    error InvalidContributors();
    error ZeroAddress();
    error ZeroPrice();
    error ZeroDuration();
    error ZeroPurposeMask();
    error ZeroHash();
    error SelfRequest();
    error InvalidChoice();
    error AlreadyRevoked();
    error NotAContributor();
    error TransferFailed();
    error NoBalance();

    // Events
    event DatasetRegistered(
        uint256 indexed datasetId,
        address indexed steward,
        Ownership ownership,
        uint256 price,
        uint8 purposeMask
    );
    event TermsUpdated(
        uint256 indexed datasetId,
        uint256 price,
        uint64 licenceDuration,
        uint8 purposeMask
    );
    event CouncilUpdated(
        uint256 indexed datasetId,
        uint32 indexed newVersion,
        uint256 memberCount
    );
    event LicenceRequested(
        uint256 indexed requestId,
        uint256 indexed datasetId,
        address indexed requester,
        Purpose purpose,
        uint256 escrow,
        uint64 deadline
    );
    event VoteCast(
        uint256 indexed requestId,
        address indexed voter,
        Choice choice
    );
    event RequestApproved(uint256 indexed requestId, uint64 expiresAt);
    event RequestRejected(uint256 indexed requestId);
    event RequestExpired(uint256 indexed requestId);
    event RequestCancelled(uint256 indexed requestId);
    event PaymentCredited(
        uint256 indexed requestId,
        address indexed recipient,
        uint256 amount
    );
    event Withdrawn(address indexed account, uint256 amount);
    event ConsentRevoked(uint256 indexed datasetId, address indexed contributor);
    event LicenceMinted(
        uint256 indexed tokenId,
        uint256 indexed datasetId,
        address indexed holder
    );
    event DeliveryRecorded(uint256 indexed requestId, bytes32 fingerprint);
    event DatasetPaused(uint256 indexed datasetId, bool paused);

    constructor(
        address admin,
        address licence,
        address _platformTreasury,
        address relayer
    ) EIP712("VaaniVault", "1") {
        if (admin == address(0) || licence == address(0) || _platformTreasury == address(0)) {
            revert ZeroAddress();
        }
        _grantRole(DEFAULT_ADMIN_ROLE, admin);
        _grantRole(ADMIN_ROLE, admin);
        if (relayer != address(0)) {
            _grantRole(DELIVERY_ROLE, relayer);
        }

        licenceContract = VaaniLicence(licence);
        platformTreasury = _platformTreasury;
    }

    // ==========================================
    // Dataset Management
    // ==========================================

    function registerDataset(
        RegisterParams calldata p,
        bytes32 salt,
        address[] calldata contributorList,
        uint32[] calldata contributorWeights,
        address[] calldata councilMembers
    ) external returns (uint256 datasetId) {
        datasetId = uint256(keccak256(abi.encode(msg.sender, salt)));
        if (_datasets[datasetId].steward != address(0)) revert DatasetExists();

        if (uint256(p.contributorsBps) + p.communityBps + p.platformBps != 10000) {
            revert InvalidSplit();
        }
        if (p.communityFund == address(0)) revert ZeroAddress();
        if (p.price == 0) revert ZeroPrice();
        if (p.licenceDuration == 0) revert ZeroDuration();
        if (p.purposeMask == 0) revert ZeroPurposeMask();

        uint256 cLen = contributorList.length;
        if (cLen == 0 || cLen > 50 || cLen != contributorWeights.length) {
            revert InvalidContributors();
        }

        uint32 totalWeight = 0;
        for (uint256 i = 0; i < cLen; i++) {
            address c = contributorList[i];
            if (c == address(0)) revert ZeroAddress();
            if (weight[datasetId][c] > 0) revert InvalidContributors(); // duplicate
            uint32 w = contributorWeights[i];
            if (w == 0) revert InvalidContributors();
            weight[datasetId][c] = w;
            totalWeight += w;
            _contributors[datasetId].push(c);
        }

        if (p.ownership == Ownership.Community) {
            uint256 councilLen = councilMembers.length;
            if (
                councilLen == 0 ||
                councilLen > 15 ||
                p.threshold == 0 ||
                p.threshold > councilLen ||
                p.quorum == 0 ||
                p.quorum > councilLen ||
                p.votingPeriod == 0
            ) {
                revert InvalidCouncil();
            }

            for (uint256 i = 0; i < councilLen; i++) {
                address m = councilMembers[i];
                if (m == address(0)) revert ZeroAddress();
                if (_isCouncil[datasetId][1][m]) revert InvalidCouncil(); // duplicate
                _isCouncil[datasetId][1][m] = true;
                _councils[datasetId][1].push(m);
            }
        } else {
            if (councilMembers.length != 0 || p.votingPeriod == 0) {
                revert InvalidCouncil();
            }
        }

        _datasets[datasetId] = Dataset({
            steward: msg.sender,
            ownership: p.ownership,
            manifestHash: p.manifestHash,
            consentRoot: p.consentRoot,
            metadataURI: p.metadataURI,
            price: p.price,
            licenceDuration: p.licenceDuration,
            purposeMask: p.purposeMask,
            contributorsBps: p.contributorsBps,
            communityBps: p.communityBps,
            platformBps: p.platformBps,
            communityFund: p.communityFund,
            threshold: p.threshold,
            quorum: p.quorum,
            votingPeriod: p.votingPeriod,
            councilVersion: 1,
            requestNonce: 0,
            activeWeight: totalWeight,
            paused: false
        });

        emit DatasetRegistered(datasetId, msg.sender, p.ownership, p.price, p.purposeMask);
    }

    function updateTerms(
        uint256 datasetId,
        uint256 price,
        uint64 licenceDuration,
        uint8 purposeMask
    ) external {
        Dataset storage d = _datasets[datasetId];
        if (d.steward == address(0)) revert DatasetNotFound();
        if (msg.sender != d.steward) revert NotSteward();
        if (price == 0) revert ZeroPrice();
        if (licenceDuration == 0) revert ZeroDuration();
        if (purposeMask == 0) revert ZeroPurposeMask();

        d.price = price;
        d.licenceDuration = licenceDuration;
        d.purposeMask = purposeMask;

        emit TermsUpdated(datasetId, price, licenceDuration, purposeMask);
    }

    function updateCouncil(
        uint256 datasetId,
        address[] calldata newMembers
    ) external {
        Dataset storage d = _datasets[datasetId];
        if (d.steward == address(0)) revert DatasetNotFound();
        if (msg.sender != d.steward) revert NotSteward();
        if (d.ownership != Ownership.Community) revert NotCommunity();

        uint256 councilLen = newMembers.length;
        if (
            councilLen == 0 ||
            councilLen > 15 ||
            d.threshold > councilLen ||
            d.quorum > councilLen
        ) {
            revert InvalidCouncil();
        }

        uint32 newVersion = d.councilVersion + 1;
        d.councilVersion = newVersion;

        for (uint256 i = 0; i < councilLen; i++) {
            address m = newMembers[i];
            if (m == address(0)) revert ZeroAddress();
            if (_isCouncil[datasetId][newVersion][m]) revert InvalidCouncil(); // duplicate
            _isCouncil[datasetId][newVersion][m] = true;
            _councils[datasetId][newVersion].push(m);
        }

        emit CouncilUpdated(datasetId, newVersion, councilLen);
    }

    function setPaused(uint256 datasetId, bool paused) external onlyRole(ADMIN_ROLE) {
        Dataset storage d = _datasets[datasetId];
        if (d.steward == address(0)) revert DatasetNotFound();
        d.paused = paused;
        emit DatasetPaused(datasetId, paused);
    }

    // ==========================================
    // Licence Request Flow
    // ==========================================

    function requestLicence(
        uint256 datasetId,
        Purpose purpose,
        bytes32 useHash,
        bytes32 agreementHash
    ) external payable returns (uint256 requestId) {
        Dataset storage d = _datasets[datasetId];
        if (d.steward == address(0)) revert DatasetNotFound();
        if (d.paused) revert Paused();
        if (msg.sender == d.steward) revert SelfRequest();
        if (useHash == bytes32(0) || agreementHash == bytes32(0)) revert ZeroHash();

        uint8 purposeBit = uint8(1) << uint8(purpose);
        if ((d.purposeMask & purposeBit) == 0) revert PurposeNotAllowed();
        if (msg.value != d.price) revert WrongPayment();

        requestId = uint256(keccak256(abi.encode(datasetId, d.requestNonce++)));

        bytes32 termsHash = keccak256(
            abi.encode(
                d.price,
                d.contributorsBps,
                d.communityBps,
                d.platformBps,
                d.licenceDuration,
                d.manifestHash,
                d.consentRoot
            )
        );

        uint64 deadline = uint64(block.timestamp + d.votingPeriod);

        _requests[requestId] = Request({
            datasetId: datasetId,
            requester: msg.sender,
            purpose: purpose,
            useHash: useHash,
            agreementHash: agreementHash,
            termsHash: termsHash,
            escrow: msg.value,
            deadline: deadline,
            councilVersion: d.councilVersion,
            approvals: 0,
            rejections: 0,
            abstains: 0,
            status: Status.Pending,
            expiresAt: 0,
            deliveryFingerprint: bytes32(0)
        });

        emit LicenceRequested(requestId, datasetId, msg.sender, purpose, msg.value, deadline);
    }

    // ==========================================
    // Voting & Decisions
    // ==========================================

    function castVoteBySig(
        uint256 requestId,
        address voter,
        Choice choice,
        uint256 deadline,
        bytes calldata signature
    ) external {
        if (block.timestamp > deadline) revert SignatureExpired();

        bytes32 structHash = keccak256(
            abi.encode(VOTE_TYPEHASH, requestId, voter, uint8(choice), nonces[voter]++, deadline)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        if (signer != voter) revert BadSignature();

        _processVote(requestId, voter, choice);
    }

    function castVote(uint256 requestId, Choice choice) external {
        _processVote(requestId, msg.sender, choice);
    }

    function _processVote(uint256 requestId, address voter, Choice choice) internal {
        Request storage r = _requests[requestId];
        if (r.status != Status.Pending) revert NotPending();
        if (block.timestamp >= r.deadline) revert DeadlinePassed();
        if (choice == Choice.None) revert InvalidChoice();

        Dataset storage d = _datasets[r.datasetId];
        if (d.ownership != Ownership.Community) revert NotCommunity();
        if (voter == r.requester) revert NotCouncil(); // Requester conflict rule
        if (!_isCouncil[r.datasetId][r.councilVersion][voter]) revert NotCouncil();
        if (_votes[requestId][voter] != Choice.None) revert AlreadyVoted();

        _votes[requestId][voter] = choice;

        if (choice == Choice.Approve) {
            r.approvals++;
        } else if (choice == Choice.Reject) {
            r.rejections++;
        } else if (choice == Choice.Abstain) {
            r.abstains++;
        }

        emit VoteCast(requestId, voter, choice);

        uint8 threshold = d.threshold;
        uint256 councilSize = _councils[r.datasetId][r.councilVersion].length;
        uint256 votesCast = r.approvals + r.rejections + r.abstains;

        // Early approve check
        if (r.approvals >= threshold) {
            _settle(requestId);
            return;
        }

        // Early reject check: remaining potential approvals cannot reach threshold
        uint256 remainingVoters = councilSize - votesCast;
        if (r.approvals + remainingVoters < threshold) {
            _refund(requestId, Status.Rejected);
        }
    }

    function decide(uint256 requestId, bool approve) external {
        Request storage r = _requests[requestId];
        if (r.status != Status.Pending) revert NotPending();
        if (block.timestamp >= r.deadline) revert DeadlinePassed();

        Dataset storage d = _datasets[r.datasetId];
        if (d.ownership != Ownership.Individual) revert NotIndividual();
        if (msg.sender != d.steward) revert NotSteward();

        if (approve) {
            _settle(requestId);
        } else {
            _refund(requestId, Status.Rejected);
        }
    }

    function finalize(uint256 requestId) external {
        Request storage r = _requests[requestId];
        if (r.status != Status.Pending) revert NotPending();
        if (block.timestamp < r.deadline) revert DeadlineNotReached();

        Dataset storage d = _datasets[r.datasetId];
        if (d.ownership == Ownership.Individual) {
            _refund(requestId, Status.Expired);
            return;
        }

        uint256 votesCast = r.approvals + r.rejections + r.abstains;
        if (votesCast >= d.quorum) {
            _refund(requestId, Status.Rejected);
        } else {
            _refund(requestId, Status.Expired);
        }
    }

    function cancel(uint256 requestId) external {
        Request storage r = _requests[requestId];
        if (r.status != Status.Pending) revert NotPending();
        if (msg.sender != r.requester) revert NotRequester();

        _refund(requestId, Status.Cancelled);
    }

    // ==========================================
    // Settlement & Refund Internal
    // ==========================================

    function _settle(uint256 requestId) internal {
        Request storage r = _requests[requestId];
        Dataset storage d = _datasets[r.datasetId];

        r.status = Status.Approved;
        uint64 expiry = uint64(block.timestamp + d.licenceDuration);
        r.expiresAt = expiry;
        _latestLicence[r.datasetId][r.requester][r.purpose] = requestId;

        uint256 escrowAmount = r.escrow;
        uint256 platformShare = (escrowAmount * d.platformBps) / 10000;
        balances[platformTreasury] += platformShare;
        emit PaymentCredited(requestId, platformTreasury, platformShare);

        uint256 pool = (escrowAmount * d.contributorsBps) / 10000;
        uint256 contributorSum = 0;
        address[] storage cList = _contributors[r.datasetId];
        uint256 cLen = cList.length;

        if (d.activeWeight == 0) {
            // Entire pool goes to community fund if all active weight revoked
            contributorSum = 0;
        } else {
            for (uint256 i = 0; i < cLen; i++) {
                address c = cList[i];
                if (!revoked[r.datasetId][c]) {
                    uint32 w = weight[r.datasetId][c];
                    uint256 share = (pool * w) / d.activeWeight;
                    balances[c] += share;
                    contributorSum += share;
                    emit PaymentCredited(requestId, c, share);
                }
            }
        }

        uint256 communityShare = escrowAmount - platformShare - contributorSum;
        balances[d.communityFund] += communityShare;
        emit PaymentCredited(requestId, d.communityFund, communityShare);

        emit RequestApproved(requestId, expiry);

        // Mint soulbound licence token
        licenceContract.mint(r.requester, requestId);
        emit LicenceMinted(requestId, r.datasetId, r.requester);
    }

    function _refund(uint256 requestId, Status outcomeStatus) internal {
        Request storage r = _requests[requestId];
        r.status = outcomeStatus;

        uint256 amount = r.escrow;
        balances[r.requester] += amount;
        emit PaymentCredited(requestId, r.requester, amount);

        if (outcomeStatus == Status.Rejected) {
            emit RequestRejected(requestId);
        } else if (outcomeStatus == Status.Expired) {
            emit RequestExpired(requestId);
        } else if (outcomeStatus == Status.Cancelled) {
            emit RequestCancelled(requestId);
        }
    }

    // ==========================================
    // Consent Revocation & Withdrawals
    // ==========================================

    function revokeConsentBySig(
        uint256 datasetId,
        address contributor,
        uint256 deadline,
        bytes calldata signature
    ) external {
        if (block.timestamp > deadline) revert SignatureExpired();

        bytes32 structHash = keccak256(
            abi.encode(REVOKE_TYPEHASH, datasetId, contributor, nonces[contributor]++, deadline)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        if (signer != contributor) revert BadSignature();

        _revokeConsent(datasetId, contributor);
    }

    function revokeConsent(uint256 datasetId) external {
        _revokeConsent(datasetId, msg.sender);
    }

    function _revokeConsent(uint256 datasetId, address contributor) internal {
        Dataset storage d = _datasets[datasetId];
        if (d.steward == address(0)) revert DatasetNotFound();
        if (weight[datasetId][contributor] == 0) revert NotAContributor();
        if (revoked[datasetId][contributor]) revert AlreadyRevoked();

        revoked[datasetId][contributor] = true;
        d.activeWeight -= weight[datasetId][contributor];

        emit ConsentRevoked(datasetId, contributor);
    }

    function withdraw() external nonReentrant {
        _withdraw(msg.sender);
    }

    function withdrawBySig(
        address account,
        uint256 deadline,
        bytes calldata signature
    ) external nonReentrant {
        if (block.timestamp > deadline) revert SignatureExpired();

        bytes32 structHash = keccak256(
            abi.encode(WITHDRAW_TYPEHASH, account, nonces[account]++, deadline)
        );
        bytes32 hash = _hashTypedDataV4(structHash);
        address signer = ECDSA.recover(hash, signature);
        if (signer != account) revert BadSignature();

        _withdraw(account);
    }

    function _withdraw(address account) internal {
        uint256 balance = balances[account];
        if (balance == 0) revert NoBalance();

        balances[account] = 0;
        emit Withdrawn(account, balance);

        (bool success, ) = account.call{value: balance}("");
        if (!success) revert TransferFailed();
    }

    // ==========================================
    // Delivery Service
    // ==========================================

    function recordDelivery(
        uint256 requestId,
        bytes32 fingerprint
    ) external onlyRole(DELIVERY_ROLE) {
        Request storage r = _requests[requestId];
        if (r.status != Status.Approved) revert NotPending();
        if (r.deliveryFingerprint != bytes32(0)) revert AlreadyDelivered();
        if (fingerprint == bytes32(0)) revert ZeroHash();

        r.deliveryFingerprint = fingerprint;
        emit DeliveryRecorded(requestId, fingerprint);
    }

    // ==========================================
    // Views
    // ==========================================

    function getDataset(uint256 datasetId) external view returns (Dataset memory) {
        Dataset memory d = _datasets[datasetId];
        if (d.steward == address(0)) revert DatasetNotFound();
        return d;
    }

    function getRequest(uint256 requestId) external view returns (Request memory) {
        Request memory r = _requests[requestId];
        if (r.requester == address(0)) revert NotPending();
        return r;
    }

    function getContributors(
        uint256 datasetId
    ) external view returns (address[] memory addrs, uint32[] memory weights, bool[] memory revs) {
        address[] storage list = _contributors[datasetId];
        uint256 len = list.length;
        addrs = new address[](len);
        weights = new uint32[](len);
        revs = new bool[](len);

        for (uint256 i = 0; i < len; i++) {
            address c = list[i];
            addrs[i] = c;
            weights[i] = weight[datasetId][c];
            revs[i] = revoked[datasetId][c];
        }
    }

    function getCouncil(
        uint256 datasetId,
        uint32 version
    ) external view returns (address[] memory) {
        return _councils[datasetId][version];
    }

    function voteOf(uint256 requestId, address voter) external view returns (Choice) {
        return _votes[requestId][voter];
    }

    function isLicensed(
        uint256 datasetId,
        address holder,
        Purpose purpose
    ) external view returns (bool) {
        uint256 reqId = _latestLicence[datasetId][holder][purpose];
        if (reqId == 0) return false;
        Request storage r = _requests[reqId];
        return (r.status == Status.Approved && block.timestamp < r.expiresAt);
    }

    function licenceOf(
        uint256 requestId
    )
        external
        view
        returns (
            uint256 datasetId,
            address requester,
            Purpose purpose,
            bytes32 useHash,
            bytes32 agreementHash,
            bytes32 termsHash,
            bytes32 deliveryFingerprint,
            Status status,
            uint64 expiresAt,
            uint256 escrow
        )
    {
        Request storage r = _requests[requestId];
        return (
            r.datasetId,
            r.requester,
            r.purpose,
            r.useHash,
            r.agreementHash,
            r.termsHash,
            r.deliveryFingerprint,
            r.status,
            r.expiresAt,
            r.escrow
        );
    }

    // EIP-712 Hashes
    function domainSeparator() external view returns (bytes32) {
        return _domainSeparatorV4();
    }

    function hashVote(
        uint256 requestId,
        address voter,
        Choice choice,
        uint256 nonce,
        uint256 deadline
    ) external view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(VOTE_TYPEHASH, requestId, voter, uint8(choice), nonce, deadline)
        );
        return _hashTypedDataV4(structHash);
    }

    function hashRevoke(
        uint256 datasetId,
        address contributor,
        uint256 nonce,
        uint256 deadline
    ) external view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(REVOKE_TYPEHASH, datasetId, contributor, nonce, deadline)
        );
        return _hashTypedDataV4(structHash);
    }

    function hashWithdraw(
        address account,
        uint256 nonce,
        uint256 deadline
    ) external view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(WITHDRAW_TYPEHASH, account, nonce, deadline)
        );
        return _hashTypedDataV4(structHash);
    }
}
