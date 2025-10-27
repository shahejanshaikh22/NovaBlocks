// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title NovaBlocks
 * @dev A dynamic NFT system where blocks evolve and gain power over time
 */
contract NovaBlocks {
    struct NovaBlock {
        uint256 id;
        uint256 power;
        uint256 generation;
        uint256 birthTime;
        address owner;
        string color;
        bool isActive;
    }
    
    mapping(uint256 => NovaBlock) public blocks;
    mapping(address => uint256[]) public ownerBlocks;
    
    uint256 public nextBlockId = 1;
    uint256 public constant EVOLUTION_TIME = 7 days;
    uint256 public constant BASE_POWER = 100;
    uint256 public constant CREATION_FEE = 0.01 ether;
    
    event BlockCreated(uint256 indexed blockId, address indexed owner, uint256 generation);
    event BlockEvolved(uint256 indexed blockId, uint256 newPower, uint256 newGeneration);
    event BlockMerged(uint256 indexed block1, uint256 indexed block2, uint256 newBlockId);
    
    function createBlock() external payable {
        require(msg.value >= CREATION_FEE, "Insufficient payment");
        
        uint256 blockId = nextBlockId++;
        string memory color = _generateColor(blockId);
        
        blocks[blockId] = NovaBlock({
            id: blockId,
            power: BASE_POWER,
            generation: 1,
            birthTime: block.timestamp,
            owner: msg.sender,
            color: color,
            isActive: true
        });
        
        ownerBlocks[msg.sender].push(blockId);
        emit BlockCreated(blockId, msg.sender, 1);
    }
    
    function _generateColor(uint256 blockId) internal view returns (string memory) {
        uint256 randomNum = uint256(keccak256(abi.encodePacked(block.timestamp, blockId, msg.sender))) % 6;
        
        if (randomNum == 0) return "Red";
        if (randomNum == 1) return "Blue";
        if (randomNum == 2) return "Green";
        if (randomNum == 3) return "Purple";
        if (randomNum == 4) return "Gold";
        return "Silver";
    }
    
    function evolveBlock(uint256 blockId) external {
        NovaBlock storage nova = blocks[blockId];
        require(nova.owner == msg.sender, "Not the owner");
        require(nova.isActive, "Block is inactive");
        require(block.timestamp >= nova.birthTime + EVOLUTION_TIME, "Evolution time not reached");
        
        nova.generation++;
        nova.power = nova.power + (BASE_POWER * nova.generation / 2);
        nova.birthTime = block.timestamp;
        
        emit BlockEvolved(blockId, nova.power, nova.generation);
    }
    
    function mergeBlocks(uint256 blockId1, uint256 blockId2) external {
        require(blocks[blockId1].owner == msg.sender && blocks[blockId2].owner == msg.sender, "Not owner of both blocks");
        require(blocks[blockId1].isActive && blocks[blockId2].isActive, "Blocks must be active");
        
        uint256 newBlockId = nextBlockId++;
        uint256 combinedPower = blocks[blockId1].power + blocks[blockId2].power;
        uint256 higherGen = blocks[blockId1].generation > blocks[blockId2].generation ? 
                            blocks[blockId1].generation : blocks[blockId2].generation;
        
        blocks[blockId1].isActive = false;
        blocks[blockId2].isActive = false;
        
        blocks[newBlockId] = NovaBlock({
            id: newBlockId,
            power: combinedPower,
            generation: higherGen + 1,
            birthTime: block.timestamp,
            owner: msg.sender,
            color: blocks[blockId1].color,
            isActive: true
        });
        
        ownerBlocks[msg.sender].push(newBlockId);
        emit BlockMerged(blockId1, blockId2, newBlockId);
    }
    
    function getBlockPower(uint256 blockId) external view returns (uint256) {
        return blocks[blockId].power;
    }
    
    function getOwnerBlocks(address owner) external view returns (uint256[] memory) {
        return ownerBlocks[owner];
    }
    
    function getMyBlocks() external view returns (uint256[] memory) {
        return ownerBlocks[msg.sender];
    }
}