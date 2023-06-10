// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../interfaces/IExecutableProposal.sol"; 

contract Proposal is IExecutableProposal{

    event execute(uint proposalId, uint numVotes, uint numTokens); 

    function executeProposal(uint proposalId, uint numVotes, uint numTokens) override  external payable{
        emit execute(proposalId, numVotes, numTokens); 
    }



    
}