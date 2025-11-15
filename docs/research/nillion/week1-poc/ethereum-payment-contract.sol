// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title PermamindPaymentGate
 * @dev Payment gating contract for Nillion-based M2M AI marketplace
 * @notice This contract manages payment credits for AI service execution on Nillion
 *
 * ARCHITECTURE OVERVIEW:
 * 1. User buys credits by paying ETH
 * 2. Credits are locked for specific service IDs (hashed identifiers)
 * 3. Nillion executor (TEE-verified) consumes credits atomically before execution
 * 4. Failed executions can be refunded by authorized executors
 *
 * SECURITY MODEL:
 * - Executors must provide TEE attestation proof
 * - Only verified executors can consume/refund credits
 * - Reentrancy protection on all state-changing functions
 * - Emergency pause mechanism for critical issues
 */

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PermamindPaymentGate is ReentrancyGuard, Pausable, Ownable {

    // ============ State Variables ============

    /// @notice Maps user address => service ID => available credits
    mapping(address => mapping(bytes32 => uint256)) public credits;

    /// @notice Service pricing: service ID => price per credit in wei
    mapping(bytes32 => uint256) public servicePrices;

    /// @notice Service metadata: service ID => service info
    mapping(bytes32 => ServiceInfo) public services;

    /// @notice Executor authorization: executor address => is authorized
    mapping(address => bool) public authorizedExecutors;

    /// @notice TEE attestation registry: executor address => attestation hash
    mapping(address => bytes32) public executorAttestations;

    /// @notice Execution receipts for audit trail
    mapping(bytes32 => ExecutionReceipt) public executionReceipts;

    /// @notice Total credits sold per service (for analytics)
    mapping(bytes32 => uint256) public totalCreditsSold;

    /// @notice Total credits consumed per service (for analytics)
    mapping(bytes32 => uint256) public totalCreditsConsumed;

    // ============ Structs ============

    struct ServiceInfo {
        string name;
        address creator;
        uint256 pricePerCredit;
        uint256 creatorRevShare; // basis points (e.g., 1500 = 15%)
        bool active;
        uint256 createdAt;
    }

    struct ExecutionReceipt {
        address user;
        address executor;
        bytes32 serviceId;
        uint256 creditsConsumed;
        uint256 timestamp;
        bool refunded;
        string nillionTxId; // Reference to Nillion execution
    }

    // ============ Events ============

    event ServiceRegistered(
        bytes32 indexed serviceId,
        string name,
        address indexed creator,
        uint256 pricePerCredit,
        uint256 creatorRevShare
    );

    event CreditsPurchased(
        address indexed user,
        bytes32 indexed serviceId,
        uint256 amount,
        uint256 totalCost
    );

    event CreditsConsumed(
        address indexed user,
        address indexed executor,
        bytes32 indexed serviceId,
        uint256 amount,
        bytes32 receiptId,
        string nillionTxId
    );

    event CreditsRefunded(
        address indexed user,
        bytes32 indexed serviceId,
        uint256 amount,
        bytes32 receiptId,
        string reason
    );

    event ExecutorAuthorized(
        address indexed executor,
        bytes32 attestationHash
    );

    event ExecutorRevoked(
        address indexed executor
    );

    event ServiceDeactivated(
        bytes32 indexed serviceId
    );

    event RevenueWithdrawn(
        bytes32 indexed serviceId,
        address indexed creator,
        uint256 amount
    );

    // ============ Modifiers ============

    modifier onlyAuthorizedExecutor() {
        require(authorizedExecutors[msg.sender], "Not authorized executor");
        _;
    }

    modifier serviceExists(bytes32 serviceId) {
        require(services[serviceId].active, "Service not active");
        _;
    }

    // ============ Constructor ============

    constructor() {
        // Contract deployer is initial owner
    }

    // ============ Service Management Functions ============

    /**
     * @notice Register a new AI service
     * @param serviceId Unique identifier for the service (hash of service name/metadata)
     * @param name Human-readable service name
     * @param pricePerCredit Price in wei for one credit
     * @param creatorRevShare Revenue share for creator in basis points (max 5000 = 50%)
     */
    function registerService(
        bytes32 serviceId,
        string calldata name,
        uint256 pricePerCredit,
        uint256 creatorRevShare
    ) external whenNotPaused {
        require(services[serviceId].createdAt == 0, "Service already exists");
        require(pricePerCredit > 0, "Price must be > 0");
        require(creatorRevShare <= 5000, "Rev share too high"); // Max 50%
        require(bytes(name).length > 0, "Name required");

        services[serviceId] = ServiceInfo({
            name: name,
            creator: msg.sender,
            pricePerCredit: pricePerCredit,
            creatorRevShare: creatorRevShare,
            active: true,
            createdAt: block.timestamp
        });

        servicePrices[serviceId] = pricePerCredit;

        emit ServiceRegistered(
            serviceId,
            name,
            msg.sender,
            pricePerCredit,
            creatorRevShare
        );
    }

    /**
     * @notice Deactivate a service (only creator can deactivate)
     * @param serviceId Service to deactivate
     */
    function deactivateService(bytes32 serviceId) external {
        require(services[serviceId].creator == msg.sender, "Not service creator");
        require(services[serviceId].active, "Already inactive");

        services[serviceId].active = false;
        emit ServiceDeactivated(serviceId);
    }

    // ============ Credit Purchase Functions ============

    /**
     * @notice Buy credits for a specific service
     * @param serviceId Service to buy credits for
     * @param creditAmount Number of credits to purchase
     */
    function buyCredits(bytes32 serviceId, uint256 creditAmount)
        external
        payable
        whenNotPaused
        serviceExists(serviceId)
        nonReentrant
    {
        require(creditAmount > 0, "Amount must be > 0");

        uint256 totalCost = servicePrices[serviceId] * creditAmount;
        require(msg.value >= totalCost, "Insufficient payment");

        credits[msg.sender][serviceId] += creditAmount;
        totalCreditsSold[serviceId] += creditAmount;

        emit CreditsPurchased(msg.sender, serviceId, creditAmount, totalCost);

        // Refund excess payment
        if (msg.value > totalCost) {
            uint256 excess = msg.value - totalCost;
            (bool success, ) = msg.sender.call{value: excess}("");
            require(success, "Refund failed");
        }
    }

    /**
     * @notice Check credit balance for a user and service
     * @param user User address
     * @param serviceId Service ID
     * @return Available credits
     */
    function getCredits(address user, bytes32 serviceId)
        external
        view
        returns (uint256)
    {
        return credits[user][serviceId];
    }

    // ============ Execution & Credit Consumption Functions ============

    /**
     * @notice Verify user has credits and consume them atomically
     * @dev Called by Nillion executor before running computation
     * @param user User requesting the service
     * @param serviceId Service being executed
     * @param amount Credits to consume
     * @param nillionTxId Reference to Nillion execution transaction
     * @return receiptId Unique receipt ID for this execution
     */
    function verifyAndConsumeCredits(
        address user,
        bytes32 serviceId,
        uint256 amount,
        string calldata nillionTxId
    )
        external
        whenNotPaused
        onlyAuthorizedExecutor
        serviceExists(serviceId)
        nonReentrant
        returns (bytes32 receiptId)
    {
        require(credits[user][serviceId] >= amount, "Insufficient credits");
        require(bytes(nillionTxId).length > 0, "Nillion TX ID required");

        // Consume credits BEFORE execution (atomic payment gating)
        credits[user][serviceId] -= amount;
        totalCreditsConsumed[serviceId] += amount;

        // Generate unique receipt
        receiptId = keccak256(abi.encodePacked(
            user,
            msg.sender,
            serviceId,
            amount,
            block.timestamp,
            nillionTxId
        ));

        // Store execution receipt
        executionReceipts[receiptId] = ExecutionReceipt({
            user: user,
            executor: msg.sender,
            serviceId: serviceId,
            creditsConsumed: amount,
            timestamp: block.timestamp,
            refunded: false,
            nillionTxId: nillionTxId
        });

        emit CreditsConsumed(
            user,
            msg.sender,
            serviceId,
            amount,
            receiptId,
            nillionTxId
        );

        return receiptId;
    }

    /**
     * @notice Refund credits for failed execution
     * @dev Only authorized executors can refund (prevents user self-refunds)
     * @param receiptId Execution receipt to refund
     * @param reason Reason for refund
     */
    function refundExecution(
        bytes32 receiptId,
        string calldata reason
    )
        external
        whenNotPaused
        onlyAuthorizedExecutor
        nonReentrant
    {
        ExecutionReceipt storage receipt = executionReceipts[receiptId];
        require(receipt.timestamp > 0, "Receipt not found");
        require(!receipt.refunded, "Already refunded");
        require(receipt.executor == msg.sender, "Not executor");

        receipt.refunded = true;
        credits[receipt.user][receipt.serviceId] += receipt.creditsConsumed;
        totalCreditsConsumed[receipt.serviceId] -= receipt.creditsConsumed;

        emit CreditsRefunded(
            receipt.user,
            receipt.serviceId,
            receipt.creditsConsumed,
            receiptId,
            reason
        );
    }

    // ============ Executor Management Functions ============

    /**
     * @notice Authorize a Nillion executor with TEE attestation
     * @param executor Executor address
     * @param attestationHash Hash of TEE attestation proof
     * @dev In production, this would verify AMD SEV-SNP or NVIDIA attestation
     */
    function authorizeExecutor(
        address executor,
        bytes32 attestationHash
    )
        external
        onlyOwner
    {
        require(executor != address(0), "Invalid executor");
        require(attestationHash != bytes32(0), "Invalid attestation");

        authorizedExecutors[executor] = true;
        executorAttestations[executor] = attestationHash;

        emit ExecutorAuthorized(executor, attestationHash);
    }

    /**
     * @notice Revoke executor authorization
     * @param executor Executor to revoke
     */
    function revokeExecutor(address executor) external onlyOwner {
        require(authorizedExecutors[executor], "Not authorized");

        authorizedExecutors[executor] = false;
        delete executorAttestations[executor];

        emit ExecutorRevoked(executor);
    }

    /**
     * @notice Verify executor attestation (placeholder for full TEE verification)
     * @param executor Executor address
     * @return True if executor is authorized with valid attestation
     */
    function verifyExecutorAttestation(address executor)
        external
        view
        returns (bool)
    {
        return authorizedExecutors[executor] &&
               executorAttestations[executor] != bytes32(0);
    }

    // ============ Revenue Management Functions ============

    /**
     * @notice Calculate revenue split for a service
     * @param serviceId Service ID
     * @param totalRevenue Total revenue to split
     * @return creatorShare Amount for service creator
     * @return platformShare Amount for platform
     */
    function calculateRevenueSplit(bytes32 serviceId, uint256 totalRevenue)
        public
        view
        returns (uint256 creatorShare, uint256 platformShare)
    {
        ServiceInfo memory service = services[serviceId];
        creatorShare = (totalRevenue * service.creatorRevShare) / 10000;
        platformShare = totalRevenue - creatorShare;
    }

    /**
     * @notice Withdraw accumulated revenue for service creator
     * @param serviceId Service to withdraw from
     */
    function withdrawCreatorRevenue(bytes32 serviceId)
        external
        nonReentrant
    {
        ServiceInfo memory service = services[serviceId];
        require(service.creator == msg.sender, "Not creator");

        uint256 totalRevenue = totalCreditsConsumed[serviceId] * service.pricePerCredit;
        (uint256 creatorShare, ) = calculateRevenueSplit(serviceId, totalRevenue);

        require(creatorShare > 0, "No revenue to withdraw");

        // Reset consumed credits tracking (simplified - production would track withdrawals)
        totalCreditsConsumed[serviceId] = 0;

        (bool success, ) = service.creator.call{value: creatorShare}("");
        require(success, "Transfer failed");

        emit RevenueWithdrawn(serviceId, service.creator, creatorShare);
    }

    // ============ Admin Functions ============

    /**
     * @notice Emergency pause
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @notice Unpause
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @notice Withdraw platform revenue
     * @param amount Amount to withdraw
     */
    function withdrawPlatformRevenue(uint256 amount)
        external
        onlyOwner
        nonReentrant
    {
        require(amount <= address(this).balance, "Insufficient balance");

        (bool success, ) = owner().call{value: amount}("");
        require(success, "Transfer failed");
    }

    // ============ View Functions ============

    /**
     * @notice Get service information
     * @param serviceId Service ID
     * @return Service details
     */
    function getServiceInfo(bytes32 serviceId)
        external
        view
        returns (ServiceInfo memory)
    {
        return services[serviceId];
    }

    /**
     * @notice Get execution receipt
     * @param receiptId Receipt ID
     * @return Receipt details
     */
    function getExecutionReceipt(bytes32 receiptId)
        external
        view
        returns (ExecutionReceipt memory)
    {
        return executionReceipts[receiptId];
    }

    /**
     * @notice Get service analytics
     * @param serviceId Service ID
     * @return sold Total credits sold
     * @return consumed Total credits consumed
     * @return revenue Total revenue generated
     */
    function getServiceAnalytics(bytes32 serviceId)
        external
        view
        returns (
            uint256 sold,
            uint256 consumed,
            uint256 revenue
        )
    {
        sold = totalCreditsSold[serviceId];
        consumed = totalCreditsConsumed[serviceId];
        revenue = consumed * servicePrices[serviceId];
    }
}
