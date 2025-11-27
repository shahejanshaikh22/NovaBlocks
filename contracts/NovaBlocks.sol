// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/**
 * @title NovaBlocks
 * @dev Registry for modular "blocks" of content with versioning and tagging
 * @notice Creators can register blocks, update them by creating new versions, and toggle activity
 */
contract NovaBlocks {
    address public owner;

    struct BlockMeta {
        uint256 id;
        address creator;
        string  label;        // human-readable label/title
        string  contentURI;   // IPFS/HTTPS/etc.
        string  tag;          // e.g. "spec", "design", "doc"
        uint256 version;      // version number for this logical block series
        uint256 createdAt;
        bool    isActive;
    }

    // logical block key => latest version id
    mapping(bytes32 => uint256) public latestVersionId;

    // versionId => BlockMeta
    mapping(uint256 => BlockMeta) public blocksById;

    // creator => versionIds
    mapping(address => uint256[]) public blocksOf;

    // logical block key => all versionIds
    mapping(bytes32 => uint256[]) public versionsOf;

    uint256 public nextVersionId;

    event BlockCreated(
        uint256 indexed versionId,
        bytes32 indexed blockKey,
        address indexed creator,
        string label,
        string tag,
        uint256 version,
        uint256 createdAt
    );

    event BlockUpdatedStatus(
        uint256 indexed versionId,
        bool isActive,
        uint256 timestamp
    );

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner");
        _;
    }

    modifier versionExists(uint256 versionId) {
        require(blocksById[versionId].creator != address(0), "Version not found");
        _;
    }

    modifier onlyCreator(uint256 versionId) {
        require(blocksById[versionId].creator == msg.sender, "Not creator");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    /**
     * @dev Create a new logical block (first version)
     * @param blockKey User-chosen logical key (e.g. keccak of name)
     * @param label Label/title for this block version
     * @param contentURI Off-chain content reference
     * @param tag Tag for categorization
     */
    function createBlock(
        bytes32 blockKey,
        string calldata label,
        string calldata contentURI,
        string calldata tag
    ) external returns (uint256 versionId) {
        require(blockKey != 0, "Invalid key");
        require(latestVersionId[blockKey] == 0, "Block key exists");

        versionId = _createVersion(blockKey, label, contentURI, tag, 1);
    }

    /**
     * @dev Create a new version for an existing logical block
     * @param blockKey Logical block key
     * @param label Label/title for this version
     * @param contentURI Off-chain content reference
     * @param tag Tag for categorization
     */
    function createNewVersion(
        bytes32 blockKey,
        string calldata label,
        string calldata contentURI,
        string calldata tag
    ) external returns (uint256 versionId) {
        uint256 currentId = latestVersionId[blockKey];
        require(currentId != 0, "Block key not found");

        BlockMeta memory current = blocksById[currentId];
        require(current.creator == msg.sender, "Not creator");

        uint256 newVersion = current.version + 1;
        versionId = _createVersion(blockKey, label, contentURI, tag, newVersion);
    }

    function _createVersion(
        bytes32 blockKey,
        string calldata label,
        string calldata contentURI,
        string calldata tag,
        uint256 version
    ) internal returns (uint256 versionId) {
        versionId = nextVersionId;
        nextVersionId += 1;

        blocksById[versionId] = BlockMeta({
            id: versionId,
            creator: msg.sender,
            label: label,
            contentURI: contentURI,
            tag: tag,
            version: version,
            createdAt: block.timestamp,
            isActive: true
        });

        latestVersionId[blockKey] = versionId;
        versionsOf[blockKey].push(versionId);
        blocksOf[msg.sender].push(versionId);

        emit BlockCreated(
            versionId,
            blockKey,
            msg.sender,
            label,
            tag,
            version,
            block.timestamp
        );
    }

    /**
     * @dev Toggle a specific version's active status
     * @param versionId Version identifier
     * @param active New active state
     */
    function setVersionActive(uint256 versionId, bool active)
        external
        versionExists(versionId)
        onlyCreator(versionId)
    {
        blocksById[versionId].isActive = active;
        emit BlockUpdatedStatus(versionId, active, block.timestamp);
    }

    /**
     * @dev Get all version ids for a given logical block key
     * @param blockKey Logical block identifier
     */
    function getVersionsOf(bytes32 blockKey)
        external
        view
        returns (uint256[] memory)
    {
        return versionsOf[blockKey];
    }

    /**
     * @dev Get all version ids created by a given address
     * @param user Address to query
     */
    function getBlocksOf(address user)
        external
        view
        returns (uint256[] memory)
    {
        return blocksOf[user];
    }

    /**
     * @dev Transfer contract ownership
     */
    function transferOwnership(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Zero address");
        address prev = owner;
        owner = newOwner;
        emit OwnershipTransferred(prev, newOwner);
    }
}
