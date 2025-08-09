// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

contract DonationApproval {
    address public owner;
    bool public paused;

    // Approval data
    struct Request {
        uint256 id;
        address student;
        uint256 amount;
        string reason;
        uint256 createdAt;
        bool approved;
        uint256 approvedAt;
        address approvedBy;
    }

    uint256 private _nextRequestId;
    mapping(uint256 => Request) public requests;
    uint256[] public requestIds;

    // Donations tracking
    mapping(address => uint256) public donations;

    // Events
    event Donated(address indexed donor, uint256 amount);
    event RequestCreated(uint256 indexed id, address indexed student, uint256 amount, string reason);
    event RequestApproved(uint256 indexed id, address indexed student, uint256 amount, address indexed admin);
    event Paused(bool paused);
    event AdminChanged(address indexed oldAdmin, address indexed newAdmin);

    // Modifiers
    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    modifier notPaused() {
        require(!paused, "Paused");
        _;
    }

    constructor() {
        owner = msg.sender;
        _nextRequestId = 1;
    }

    // --- Donation functions ---

    /// @notice Donate to the pooled fund
    function donate() external payable notPaused {
        require(msg.value > 0, "Value must be > 0");
        donations[msg.sender] += msg.value;
        emit Donated(msg.sender, msg.value);
    }

    /// @notice Get contract balance
    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    // --- Approval functions ---

    /// @notice Students create requests for funds
    function createRequest(uint256 _amount, string calldata _reason) external notPaused returns (uint256) {
        require(_amount > 0, "Amount must be > 0");
        uint256 id = _nextRequestId++;
        Request storage r = requests[id];
        r.id = id;
        r.student = msg.sender;
        r.amount = _amount;
        r.reason = _reason;
        r.createdAt = block.timestamp;
        r.approved = false;

        requestIds.push(id);
        emit RequestCreated(id, msg.sender, _amount, _reason);
        return id;
    }

    /// @notice Owner approves a student's request and disburses funds
    function approveRequest(uint256 _id) external onlyOwner notPaused {
        Request storage r = requests[_id];
        require(r.id != 0, "Request not found");
        require(!r.approved, "Already approved");
        require(r.student != owner, "Owner cannot be recipient");

        uint256 balance = getBalance();
        require(balance >= r.amount, "Insufficient balance");

        r.approved = true;
        r.approvedAt = block.timestamp;
        r.approvedBy = msg.sender;

        // Transfer funds
        (bool sent, ) = payable(r.student).call{value: r.amount}("");
        require(sent, "Transfer failed");

        emit RequestApproved(_id, r.student, r.amount, msg.sender);
    }

    /// @notice Pause/unpause donations and approvals
    function togglePause() external onlyOwner {
        paused = !paused;
        emit Paused(paused);
    }

    /// @notice Change owner/admin
    function changeOwner(address _newOwner) external onlyOwner {
        require(_newOwner != address(0), "Zero address");
        address old = owner;
        owner = _newOwner;
        emit AdminChanged(old, _newOwner);
    }

    /// @notice Get number of requests
    function getRequestCount() external view returns (uint256) {
        return requestIds.length;
    }

    /// @notice Fetch all request IDs
    function getRequestIds() external view returns (uint256[] memory) {
        return requestIds;
    }

    /// @notice Get request details by ID
    function getRequest(uint256 _id) external view returns (
        uint256 id,
        address student,
        uint256 amount,
        string memory reason,
        uint256 createdAt,
        bool approved,
        uint256 approvedAt,
        address approvedBy
    ) {
        Request storage r = requests[_id];
        require(r.id != 0, "Request not found");
        return (r.id, r.student, r.amount, r.reason, r.createdAt, r.approved, r.approvedAt, r.approvedBy);
    }

    // Fallbacks to accept donations directly
    receive() external payable {
        require(!paused, "Paused");
        require(msg.value > 0, "Value must be > 0");
        donations[msg.sender] += msg.value;
        emit Donated(msg.sender, msg.value);
    }

    fallback() external payable {
        if (msg.value > 0) {
            require(!paused, "Paused");
            donations[msg.sender] += msg.value;
            emit Donated(msg.sender, msg.value);
        }
    }
}
