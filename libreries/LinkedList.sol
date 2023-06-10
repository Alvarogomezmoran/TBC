//SPDX-License-Identifier: UNLICENSED

pragma solidity >= 0.8.0;

import "../interfaces/IExecutableProposal.sol"; 

library LinkedList {

    struct Proposal{
        Proposal proposalAddress;
        address proposalCreator;  
        string title; 
        uint256 budget; // 0 
        uint tokens; 
        uint votes; // 0 propuesta cancelada 
    }

    struct proposalNode {
        uint previos;
        uint next; 
        Proposal proposal;   
    }

    struct Propuestas{
        uint n; 
        uint first; 
        uint last; 

        mapping(uint => LinkedList.proposalNode) proposalList; 
    }
    function addProposalList(Propuestas storage propuestas, Proposal nuevaPropuesta, uint id) internal {
        uint lastNode = propuestas.last; 
        propuestas.proposalList[id] = proposalNode(lastNode, id, nuevaPropuesta);
        propuestas.proposalList[lastNode].next = id; 
        propuestas.last = id; 
        propuestas.n += 1;  
    }

    function deleteProposalList(Propuestas storage propuestas, uint id) internal {
        proposalNode memory deleteNode = propuestas.proposalList[id]; 
        // añadiendo un nodo inicial como nodo caso solo tenemos dos posibles casos 
        if(propuestas.last == id){
            propuestas.proposalList[deleteNode.previous].next = deleteNode.previous; // decimos que el ultimo nodo es el mismo para saber si ultimo nodo ultimo == lista[ultimo].next
            propuestas.last = deleteNode.previous; 

        }
        else{
            propuestas.proposalList[deleteNode.previous].next = deleteNode.next;
            propuestas.proposalList[deleteNode.next].previous = deleteNode.previous;     
        }
        propuestas.n -= 1;
        delete(propuestas.proposalList[id]);  
    }    
}





