// SPDX-License-Identifier: GPL-3.0
pragma solidity > 0.8.0;
//Implementacion of the ERC20 Implementation
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Token is ERC20 {
    address owner; 
    //uint256 immutable totalSupply; // el supply total de tokes -> precio = capitalizacionTotal / supply 

    constructor(uint256 tokens_) ERC20("nomrbe", "simbolo") {
        owner = msg.sender;
        mint(tokens_);
    }

    modifier onlyOwner(){
        require(msg.sender == owner, "Is not the owner"); 
        _; 
    }

    function mint(uint256 tokensAmount) public  onlyOwner {
        //require(getMaxSuppy() < tokensAmount, "Se ha exccedido la cantidad maxima de tokes que pueden ser creados"); 
        _mint(msg.sender, tokensAmount);


    }

    function burn(address to_account, uint256 tokensAmount) public virtual onlyOwner {
        _burn(to_account, tokensAmount); 

    }

}