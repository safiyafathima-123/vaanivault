// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {VaaniLicence} from "../src/VaaniLicence.sol";
import {VaaniVault} from "../src/VaaniVault.sol";

contract MaliciousRecipient {
    VaaniVault public vault;

    constructor(VaaniVault _vault) {
        vault = _vault;
    }

    function attack() external {
        vault.withdraw();
    }

    receive() external payable {
        // Attempt reentrancy
        vault.withdraw();
    }
}

contract VaaniVaultTest is Test {
    VaaniLicence public licence;
    VaaniVault public vault;

    address public admin = address(0xAD);
    address public platformTreasury = address(0x7E);
    uint256 public relayerKey = 0xAA11;
    address public relayer;

    uint256 public stewardKey = 0x10;
    address public steward;

    uint256 public requesterKey = 0x20;
    address public requester;

    // Voters
    uint256[] public voterKeys;
    address[] public voters;

    // Contributors
    address[] public contributors;
    uint32[] public weights;

    bytes32 public constant SAMPLE_MANIFEST = keccak256("manifest_hash");
    bytes32 public constant SAMPLE_CONSENT = keccak256("consent_root");
    bytes32 public constant SAMPLE_USE = keccak256("intended_use_research");
    bytes32 public constant SAMPLE_AGREEMENT = keccak256("agreement_hash");

    function setUp() public {
        relayer = vm.addr(relayerKey);
        steward = vm.addr(stewardKey);
        requester = vm.addr(requesterKey);

        vm.startPrank(admin);
        licence = new VaaniLicence(admin);
        vault = new VaaniVault(admin, address(licence), platformTreasury, relayer);
        licence.setVault(address(vault));
        licence.setBaseURI("https://api.vaanivault.xyz/metadata/");
        vm.stopPrank();

        // Setup 3 council voters
        for (uint256 i = 1; i <= 3; i++) {
            uint256 key = 0x100 + i;
            voterKeys.push(key);
            voters.push(vm.addr(key));
        }

        // Setup 6 contributors matching PRD section 10: 12, 8, 6, 6, 4, 4 (sum 40)
        uint32[6] memory wArray = [uint32(12), uint32(8), uint32(6), uint32(6), uint32(4), uint32(4)];
        for (uint256 i = 0; i < 6; i++) {
            address c = address(uint160(0xC000 + i + 1));
            contributors.push(c);
            weights.push(wArray[i]);
        }

        vm.deal(requester, 100 ether);
    }

    function _defaultRegisterParams() internal view returns (VaaniVault.RegisterParams memory) {
        return
            VaaniVault.RegisterParams({
                ownership: VaaniVault.Ownership.Community,
                manifestHash: SAMPLE_MANIFEST,
                consentRoot: SAMPLE_CONSENT,
                metadataURI: "ipfs://test-metadata",
                price: 1 ether,
                licenceDuration: 30 days,
                purposeMask: 0x0F, // all 4 purposes allowed (bits 0,1,2,3)
                contributorsBps: 7000,
                communityBps: 2000,
                platformBps: 1000,
                communityFund: address(0xF00D),
                threshold: 2,
                quorum: 2,
                votingPeriod: 1 days
            });
    }

    function _registerDefaultCommunity() internal returns (uint256 datasetId) {
        vm.prank(steward);
        datasetId = vault.registerDataset(
            _defaultRegisterParams(),
            keccak256("salt1"),
            contributors,
            weights,
            voters
        );
    }

    function _signVote(
        uint256 voterKey,
        uint256 requestId,
        address voterAddr,
        VaaniVault.Choice choice,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes memory) {
        bytes32 digest = vault.hashVote(requestId, voterAddr, choice, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(voterKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function _signRevoke(
        uint256 contributorKey,
        uint256 datasetId,
        address contributorAddr,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes memory) {
        bytes32 digest = vault.hashRevoke(datasetId, contributorAddr, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(contributorKey, digest);
        return abi.encodePacked(r, s, v);
    }

    function _signWithdraw(
        uint256 accountKey,
        address accountAddr,
        uint256 nonce,
        uint256 deadline
    ) internal view returns (bytes memory) {
        bytes32 digest = vault.hashWithdraw(accountAddr, nonce, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(accountKey, digest);
        return abi.encodePacked(r, s, v);
    }

    // T-01: Register with bps not summing to 10,000 -> Reverts InvalidSplit
    function test_T01_RegisterWithInvalidSplitReverts() public {
        VaaniVault.RegisterParams memory p = _defaultRegisterParams();
        p.contributorsBps = 6000; // sum is 9000

        vm.prank(steward);
        vm.expectRevert(VaaniVault.InvalidSplit.selector);
        vault.registerDataset(p, bytes32("s"), contributors, weights, voters);
    }

    // T-02: Register with 51 contributors -> Reverts InvalidContributors
    function test_T02_RegisterWith51ContributorsReverts() public {
        address[] memory manyContributors = new address[](51);
        uint32[] memory manyWeights = new uint32[](51);
        for (uint160 i = 0; i < 51; i++) {
            manyContributors[i] = address(0x5000 + i);
            manyWeights[i] = 10;
        }

        vm.prank(steward);
        vm.expectRevert(VaaniVault.InvalidContributors.selector);
        vault.registerDataset(_defaultRegisterParams(), bytes32("s"), manyContributors, manyWeights, voters);
    }

    // T-03: Request with wrong msg.value -> Reverts WrongPayment
    function test_T03_RequestWithWrongPaymentReverts() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        vm.expectRevert(VaaniVault.WrongPayment.selector);
        vault.requestLicence{value: 0.5 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );
    }

    // T-04: Request disallowed purpose or paused dataset -> Reverts
    function test_T04_DisallowedPurposeOrPausedReverts() public {
        VaaniVault.RegisterParams memory p = _defaultRegisterParams();
        p.purposeMask = 0x01; // only Purpose.Research allowed (1 << 0)

        vm.prank(steward);
        uint256 datasetId = vault.registerDataset(p, bytes32("s4"), contributors, weights, voters);

        // Disallowed purpose: CommercialTraining (1 << 1 = 2)
        vm.prank(requester);
        vm.expectRevert(VaaniVault.PurposeNotAllowed.selector);
        vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.CommercialTraining,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        // Pause dataset
        vm.prank(admin);
        vault.setPaused(datasetId, true);

        vm.prank(requester);
        vm.expectRevert(VaaniVault.Paused.selector);
        vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );
    }

    // T-05 & T-06: Two signed Approve votes via relayer; settles, credits 6 contributors, fund, platform; mints licence
    function test_T05_T06_TwoApprovedVotesSettlementAndPayouts() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        uint256 sigDeadline = block.timestamp + 1 hours;

        // Voter 1 signs Approve
        bytes memory sig1 = _signVote(
            voterKeys[0],
            requestId,
            voters[0],
            VaaniVault.Choice.Approve,
            vault.nonces(voters[0]),
            sigDeadline
        );
        vm.prank(relayer);
        vault.castVoteBySig(requestId, voters[0], VaaniVault.Choice.Approve, sigDeadline, sig1);

        assertEq(uint8(vault.voteOf(requestId, voters[0])), uint8(VaaniVault.Choice.Approve));

        // Voter 2 signs Approve (triggers early settlement threshold 2 of 3)
        bytes memory sig2 = _signVote(
            voterKeys[1],
            requestId,
            voters[1],
            VaaniVault.Choice.Approve,
            vault.nonces(voters[1]),
            sigDeadline
        );
        vm.prank(relayer);
        vault.castVoteBySig(requestId, voters[1], VaaniVault.Choice.Approve, sigDeadline, sig2);

        // Verify status
        VaaniVault.Request memory r = vault.getRequest(requestId);
        assertEq(uint8(r.status), uint8(VaaniVault.Status.Approved));

        // Verify Licence minted to requester
        assertEq(licence.ownerOf(requestId), requester);
        assertTrue(licence.locked(requestId));
        assertTrue(vault.isLicensed(datasetId, requester, VaaniVault.Purpose.Research));

        // Verify payouts exactly matching Section 10:
        // Contributors: 12/40=0.21, 8/40=0.14, 6/40=0.105, 6/40=0.105, 4/40=0.07, 4/40=0.07 MON
        assertEq(vault.balances(contributors[0]), 0.21 ether);
        assertEq(vault.balances(contributors[1]), 0.14 ether);
        assertEq(vault.balances(contributors[2]), 0.105 ether);
        assertEq(vault.balances(contributors[3]), 0.105 ether);
        assertEq(vault.balances(contributors[4]), 0.07 ether);
        assertEq(vault.balances(contributors[5]), 0.07 ether);

        // Platform: 1000 bps = 0.1 ether
        assertEq(vault.balances(platformTreasury), 0.1 ether);
        // Community fund: 2000 bps + rounding = 0.2 ether
        assertEq(vault.balances(address(0xF00D)), 0.2 ether);

        // Sum equals escrow (1 ether)
        uint256 sumCredits = vault.balances(contributors[0]) +
            vault.balances(contributors[1]) +
            vault.balances(contributors[2]) +
            vault.balances(contributors[3]) +
            vault.balances(contributors[4]) +
            vault.balances(contributors[5]) +
            vault.balances(platformTreasury) +
            vault.balances(address(0xF00D));
        assertEq(sumCredits, 1 ether);
    }

    // T-07: Fuzz test random escrow and random weights always sum exactly to escrow
    function testFuzz_T07_CreditsAlwaysSumToEscrow(uint96 escrowAmount, uint16[6] memory fWeights) public {
        vm.assume(escrowAmount > 10000);
        uint32[] memory fuzzW = new uint32[](6);
        uint32 totalW = 0;
        for (uint256 i = 0; i < 6; i++) {
            fuzzW[i] = uint32(bound(fWeights[i], 1, 1000));
            totalW += fuzzW[i];
        }

        vm.deal(requester, escrowAmount);

        VaaniVault.RegisterParams memory p = _defaultRegisterParams();
        p.price = escrowAmount;

        vm.prank(steward);
        uint256 datasetId = vault.registerDataset(
            p,
            keccak256(abi.encode(escrowAmount)),
            contributors,
            fuzzW,
            voters
        );

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: escrowAmount}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        // Two approvals
        vm.prank(voters[0]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);
        vm.prank(voters[1]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);

        uint256 sumCredits = vault.balances(platformTreasury) + vault.balances(address(0xF00D));
        for (uint256 i = 0; i < 6; i++) {
            sumCredits += vault.balances(contributors[i]);
        }
        assertEq(sumCredits, escrowAmount);
    }

    // T-08: Approve, Abstain, Reject -> Rejected on 3rd vote; refunded
    function test_T08_ApproveAbstainRejectOutcome() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(voters[0]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);
        assertEq(uint8(vault.getRequest(requestId).status), uint8(VaaniVault.Status.Pending));

        vm.prank(voters[1]);
        vault.castVote(requestId, VaaniVault.Choice.Abstain);
        assertEq(uint8(vault.getRequest(requestId).status), uint8(VaaniVault.Status.Pending));

        // 3rd vote: Reject. Total approvals = 1, remaining voters = 0 < threshold (2) -> Early Reject
        vm.prank(voters[2]);
        vault.castVote(requestId, VaaniVault.Choice.Reject);

        assertEq(uint8(vault.getRequest(requestId).status), uint8(VaaniVault.Status.Rejected));
        assertEq(vault.balances(requester), 1 ether);
    }

    // T-09: One vote then deadline, finalize() -> Expired; refunded (quorum 2 not reached)
    function test_T09_OneVoteThenDeadlineFinalizeExpired() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(voters[0]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);

        // Warp past deadline
        vm.warp(block.timestamp + 2 days);

        vault.finalize(requestId);

        assertEq(uint8(vault.getRequest(requestId).status), uint8(VaaniVault.Status.Expired));
        assertEq(vault.balances(requester), 1 ether);
    }

    // T-10: Replayed vote signature -> Reverts BadSignature (nonce used)
    function test_T10_ReplayedVoteSignatureReverts() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 req1 = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signVote(
            voterKeys[0],
            req1,
            voters[0],
            VaaniVault.Choice.Approve,
            vault.nonces(voters[0]),
            deadline
        );

        vm.prank(relayer);
        vault.castVoteBySig(req1, voters[0], VaaniVault.Choice.Approve, deadline, sig);

        // Attempting to submit the exact same signature again
        vm.prank(relayer);
        vm.expectRevert(VaaniVault.BadSignature.selector);
        vault.castVoteBySig(req1, voters[0], VaaniVault.Choice.Approve, deadline, sig);
    }

    // T-11: Signature from non-council address -> Reverts NotCouncil
    function test_T11_NonCouncilSignatureReverts() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        uint256 strangerKey = 0x9999;
        address stranger = vm.addr(strangerKey);

        bytes memory sig = _signVote(
            strangerKey,
            requestId,
            stranger,
            VaaniVault.Choice.Approve,
            vault.nonces(stranger),
            block.timestamp + 1 hours
        );

        vm.prank(relayer);
        vm.expectRevert(VaaniVault.NotCouncil.selector);
        vault.castVoteBySig(requestId, stranger, VaaniVault.Choice.Approve, block.timestamp + 1 hours, sig);
    }

    // T-12: Expired signature deadline -> Reverts SignatureExpired
    function test_T12_ExpiredSignatureDeadlineReverts() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        uint256 deadline = block.timestamp + 100;
        bytes memory sig = _signVote(
            voterKeys[0],
            requestId,
            voters[0],
            VaaniVault.Choice.Approve,
            vault.nonces(voters[0]),
            deadline
        );

        vm.warp(block.timestamp + 101);

        vm.prank(relayer);
        vm.expectRevert(VaaniVault.SignatureExpired.selector);
        vault.castVoteBySig(requestId, voters[0], VaaniVault.Choice.Approve, deadline, sig);
    }

    // T-13: Council changed during a vote -> Open request uses its snapshot
    function test_T13_CouncilSnapshotPreservedAcrossUpdates() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        // Update council with new members
        address[] memory newCouncil = new address[](3);
        newCouncil[0] = address(0xAA01);
        newCouncil[1] = address(0xAA02);
        newCouncil[2] = address(0xAA03);

        vm.prank(steward);
        vault.updateCouncil(datasetId, newCouncil);

        assertEq(vault.getDataset(datasetId).councilVersion, 2);

        // Old voter can still vote on the existing request!
        vm.prank(voters[0]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);
        assertEq(uint8(vault.voteOf(requestId, voters[0])), uint8(VaaniVault.Choice.Approve));

        // New council member cannot vote on the existing request
        vm.prank(newCouncil[0]);
        vm.expectRevert(VaaniVault.NotCouncil.selector);
        vault.castVote(requestId, VaaniVault.Choice.Approve);
    }

    // T-14: Contributor revokes before settlement -> Gets nothing; others' shares rise proportionally
    function test_T14_ContributorRevokeBeforeSettlement() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        // Contributor 0 (weight 12 out of 40) revokes consent
        vm.prank(contributors[0]);
        vault.revokeConsent(datasetId);

        assertTrue(vault.revoked(datasetId, contributors[0]));
        assertEq(vault.getDataset(datasetId).activeWeight, 28); // 40 - 12 = 28

        // Approve request
        vm.prank(voters[0]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);
        vm.prank(voters[1]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);

        // Contributor 0 received 0
        assertEq(vault.balances(contributors[0]), 0);

        // Remaining active weights: 8, 6, 6, 4, 4 (sum 28). Contributor pool = 0.7 MON
        // Contributor 1 share: 0.7 * 8 / 28 = 0.2 MON
        assertEq(vault.balances(contributors[1]), 0.2 ether);
        // Contributor 2 share: 0.7 * 6 / 28 = 0.15 MON
        assertEq(vault.balances(contributors[2]), 0.15 ether);
    }

    // T-15: withdrawBySig submitted by relayer -> Funds go to signer, not relayer
    function test_T15_WithdrawBySigFundsToSigner() public {
        // Credit some balance
        vm.deal(address(vault), 5 ether);
        // Register and approve to credit contributor 0 with 0.21 MON
        test_T05_T06_TwoApprovedVotesSettlementAndPayouts();

        uint256 c0Balance = vault.balances(contributors[0]);
        assertGt(c0Balance, 0);

        uint256 c0Key = 0x991;
        address c0Addr = vm.addr(c0Key);
        // Credit c0Addr by direct individual request
        vm.prank(steward);
        VaaniVault.RegisterParams memory p = _defaultRegisterParams();
        p.ownership = VaaniVault.Ownership.Individual;
        p.votingPeriod = 1 days;
        address[] memory singleC = new address[](1);
        singleC[0] = c0Addr;
        uint32[] memory singleW = new uint32[](1);
        singleW[0] = 10;
        address[] memory emptyCouncil;
        uint256 indId = vault.registerDataset(p, bytes32("ind1"), singleC, singleW, emptyCouncil);

        vm.prank(requester);
        uint256 reqId = vault.requestLicence{value: 1 ether}(
            indId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(steward);
        vault.decide(reqId, true);

        uint256 accrued = vault.balances(c0Addr);
        assertGt(accrued, 0);

        uint256 deadline = block.timestamp + 1 hours;
        bytes memory sig = _signWithdraw(c0Key, c0Addr, vault.nonces(c0Addr), deadline);

        uint256 beforeSignerBal = c0Addr.balance;
        uint256 beforeRelayerBal = relayer.balance;

        vm.prank(relayer);
        vault.withdrawBySig(c0Addr, deadline, sig);

        assertEq(c0Addr.balance, beforeSignerBal + accrued);
        assertEq(relayer.balance, beforeRelayerBal);
        assertEq(vault.balances(c0Addr), 0);
    }

    // T-16: Malicious recipient re-enters withdraw -> Reverts; balances unchanged
    function test_T16_MaliciousRecipientReentrancyReverts() public {
        MaliciousRecipient attacker = new MaliciousRecipient(vault);

        // Register dataset paying attacker
        address[] memory cList = new address[](1);
        cList[0] = address(attacker);
        uint32[] memory wList = new uint32[](1);
        wList[0] = 10;
        address[] memory emptyC;

        VaaniVault.RegisterParams memory p = _defaultRegisterParams();
        p.ownership = VaaniVault.Ownership.Individual;
        vm.prank(steward);
        uint256 id = vault.registerDataset(p, bytes32("atk"), cList, wList, emptyC);

        vm.prank(requester);
        uint256 reqId = vault.requestLicence{value: 1 ether}(
            id,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(steward);
        vault.decide(reqId, true);

        uint256 attackerBal = vault.balances(address(attacker));
        assertGt(attackerBal, 0);

        // Attacker calls attack() which tries to re-enter withdraw in receive()
        vm.expectRevert();
        attacker.attack();

        // Balances remain intact
        assertEq(vault.balances(address(attacker)), attackerBal);
    }

    // T-17: Licence token transfer -> Reverts (soulbound)
    function test_T17_SoulboundTransferReverts() public {
        uint256 datasetId = _registerDefaultCommunity();
        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(voters[0]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);
        vm.prank(voters[1]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);

        vm.prank(requester);
        vm.expectRevert(VaaniLicence.Soulbound.selector);
        licence.transferFrom(requester, address(0x999), requestId);
    }

    // T-18: isLicensed after expiry -> False
    function test_T18_IsLicensedAfterExpiryReturnsFalse() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(voters[0]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);
        vm.prank(voters[1]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);

        assertTrue(vault.isLicensed(datasetId, requester, VaaniVault.Purpose.Research));

        // Fast-forward past licence duration (30 days)
        vm.warp(block.timestamp + 31 days);

        assertFalse(vault.isLicensed(datasetId, requester, VaaniVault.Purpose.Research));
    }

    // T-19: recordDelivery twice or by non-delivery role -> Reverts
    function test_T19_RecordDeliveryTwiceOrUnauthorizedReverts() public {
        uint256 datasetId = _registerDefaultCommunity();
        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(voters[0]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);
        vm.prank(voters[1]);
        vault.castVote(requestId, VaaniVault.Choice.Approve);

        bytes32 canaryHash = keccak256("canary123");

        // Non-delivery role reverts
        vm.prank(requester);
        vm.expectRevert();
        vault.recordDelivery(requestId, canaryHash);

        // Delivery role succeeds
        vm.prank(relayer);
        vault.recordDelivery(requestId, canaryHash);

        // Calling second time reverts AlreadyDelivered
        vm.prank(relayer);
        vm.expectRevert(VaaniVault.AlreadyDelivered.selector);
        vault.recordDelivery(requestId, canaryHash);
    }

    // T-20: Requester cancels pending request -> Refunded; later votes revert
    function test_T20_CancelPendingRefundsAndBlocksVotes() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(requester);
        uint256 requestId = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(requester);
        vault.cancel(requestId);

        assertEq(uint8(vault.getRequest(requestId).status), uint8(VaaniVault.Status.Cancelled));
        assertEq(vault.balances(requester), 1 ether);

        // Subsequent vote reverts NotPending
        vm.prank(voters[0]);
        vm.expectRevert(VaaniVault.NotPending.selector);
        vault.castVote(requestId, VaaniVault.Choice.Approve);
    }

    // T-21: Individual owner approve and reject
    function test_T21_IndividualOwnerApproveAndReject() public {
        VaaniVault.RegisterParams memory p = _defaultRegisterParams();
        p.ownership = VaaniVault.Ownership.Individual;
        address[] memory singleC = new address[](1);
        singleC[0] = steward;
        uint32[] memory singleW = new uint32[](1);
        singleW[0] = 10;
        address[] memory emptyC;

        vm.prank(steward);
        uint256 datasetId = vault.registerDataset(p, bytes32("ind2"), singleC, singleW, emptyC);

        // Path A: Approve
        vm.prank(requester);
        uint256 req1 = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(steward);
        vault.decide(req1, true);

        assertEq(uint8(vault.getRequest(req1).status), uint8(VaaniVault.Status.Approved));
        assertTrue(vault.isLicensed(datasetId, requester, VaaniVault.Purpose.Research));

        // Path B: Reject
        vm.prank(requester);
        uint256 req2 = vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.FineTuning,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );

        vm.prank(steward);
        vault.decide(req2, false);

        assertEq(uint8(vault.getRequest(req2).status), uint8(VaaniVault.Status.Rejected));
        assertEq(vault.balances(requester), 1 ether);
    }

    // Additional test: Steward cannot request licence on own dataset
    function test_StewardCannotRequestLicence() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.deal(steward, 5 ether);
        vm.prank(steward);
        vm.expectRevert(VaaniVault.SelfRequest.selector);
        vault.requestLicence{value: 1 ether}(
            datasetId,
            VaaniVault.Purpose.Research,
            SAMPLE_USE,
            SAMPLE_AGREEMENT
        );
    }

    // Additional test: UpdateTerms affects future requests
    function test_UpdateTermsFutureRequests() public {
        uint256 datasetId = _registerDefaultCommunity();

        vm.prank(steward);
        vault.updateTerms(datasetId, 2 ether, 60 days, 0x01);

        VaaniVault.Dataset memory d = vault.getDataset(datasetId);
        assertEq(d.price, 2 ether);
        assertEq(d.licenceDuration, 60 days);
        assertEq(d.purposeMask, 0x01);
    }
}
