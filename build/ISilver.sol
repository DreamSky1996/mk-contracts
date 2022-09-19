pragma solidity ^0.8.2;


// SPDX-License-Identifier: MIT
interface ISilver {

    function burn(address from, uint256 amount) external returns (uint256);
    function isController(address _address) external view returns (bool);
    function balanceOf(address account) external view returns (uint256);
    function mint(address to, uint amount) external;
    
}