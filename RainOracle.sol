// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.7.0;

contract RainOracle {

    address public owner;

    constructor (address _owner) {
        owner = _owner;
    }

    event RainfallUpdate (uint rainfall, uint256 farmer_id);

    /*
     * emit rainfall update event
     * @param rainfall: rainfall in inches
     * @param farmer_id: farmer's id
     */
    function updateRainfall (uint rainfall, uint256 farmer_id) public {
        require (msg.sender == owner);
        emit RainfallUpdate (rainfall, farmer_id);
    }
}