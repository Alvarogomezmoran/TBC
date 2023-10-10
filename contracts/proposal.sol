// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IExecutableProposal.sol";

contract Proposal is IExecutableProposal{

    uint256[] public executedProjects;
    event execute(uint proposalId, uint numVotes, uint numTokens); 

    function executeProposal(uint proposalId, uint numVotes, uint numTokens) override  external payable{
        emit execute(proposalId, numVotes, numTokens); 
        executedProjects.push(proposalId);
        //revert();
    }
    
    function getExecuted() external view returns(uint256[] memory) {
        return executedProjects;
    }

}