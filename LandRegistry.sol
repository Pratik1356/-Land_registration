// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LandRegistry {
    struct Land {
        uint id;
        string location;
        uint area; // square feet
        address owner;
        uint registeredAt;
        bool exists;
    }

    struct Transfer {
        address from;
        address to;
        uint timestamp;
    }

    mapping(uint => Land) public lands;
    mapping(uint => Transfer[]) public history;
    mapping(address => uint[]) public ownerLands;
    uint[] public allLandIds;

    event LandRegistered(uint indexed landId, address indexed owner, string location, uint area);
    event OwnershipTransferred(uint indexed landId, address indexed from, address indexed to);

    // Register a new land parcel under the caller's address
    function registerLand(uint _landId, string memory _location, uint _area) public {
        require(!lands[_landId].exists, "Land ID already registered");
        require(_area > 0, "Area must be greater than 0");

        lands[_landId] = Land(_landId, _location, _area, msg.sender, block.timestamp, true);
        allLandIds.push(_landId);
        ownerLands[msg.sender].push(_landId);
        history[_landId].push(Transfer(address(0), msg.sender, block.timestamp));

        emit LandRegistered(_landId, msg.sender, _location, _area);
    }

    // Transfer ownership of a land parcel you currently own
    function transferOwnership(uint _landId, address _newOwner) public {
        require(lands[_landId].exists, "Land does not exist");
        require(lands[_landId].owner == msg.sender, "Only the current owner can transfer");
        require(_newOwner != address(0), "Invalid new owner");

        address previousOwner = msg.sender;
        lands[_landId].owner = _newOwner;

        // remove from previous owner's list
        uint[] storage list = ownerLands[previousOwner];
        for (uint i = 0; i < list.length; i++) {
            if (list[i] == _landId) {
                list[i] = list[list.length - 1];
                list.pop();
                break;
            }
        }
        ownerLands[_newOwner].push(_landId);

        history[_landId].push(Transfer(previousOwner, _newOwner, block.timestamp));

        emit OwnershipTransferred(_landId, previousOwner, _newOwner);
    }

    // View a land record
    function getLand(uint _landId) public view returns (
        uint id, string memory location, uint area, address owner, uint registeredAt
    ) {
        require(lands[_landId].exists, "Land does not exist");
        Land memory l = lands[_landId];
        return (l.id, l.location, l.area, l.owner, l.registeredAt);
    }

    function isRegistered(uint _landId) public view returns (bool) {
        return lands[_landId].exists;
    }

    function getOwnershipHistory(uint _landId) public view returns (Transfer[] memory) {
        require(lands[_landId].exists, "Land does not exist");
        return history[_landId];
    }

    function getLandsByOwner(address _owner) public view returns (uint[] memory) {
        return ownerLands[_owner];
    }

    function getAllLandIds() public view returns (uint[] memory) {
        return allLandIds;
    }
}
