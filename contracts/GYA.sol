//Contract based on https://docs.openzeppelin.com/contracts/3.x/erc721
// SPDX-License-Identifier: MIT
pragma solidity >0.6.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/SafeERC20.sol";

contract GYA is ERC20 {
    using Address for address;
    using SafeMath for uint256;

    address public governance;
    address public deployer;

    uint256 public initialSupply = 100000000; // 100,000,000

    modifier onlyGovernance {
        require(msg.sender == governance, "!governance");
        _;
    }
    
    constructor(address _governance) 
        ERC20("Magi GYA Token", "GYA")
    {
        governance = _governance;
        deployer = msg.sender;

        _mint(governance, initialSupply.mul(1e18));
    }

    function setGovernance(address _governance) onlyGovernance external {
        require(msg.sender == governance || msg.sender == deployer, "!governance or deployer");
        governance = _governance;
    }

    function mint(address _to, uint _amount) external onlyGovernance {
        _mint(_to, _amount);
    }
}