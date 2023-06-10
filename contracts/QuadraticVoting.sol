// SPDX-License-Identifier: GPL-3.0

pragma solidity ^0.8.0;

import "../interfaces/IExecutableProposal.sol";
import "./Token.sol"; 

contract QuadraticVoting {

    struct Proposal {
        IExecutableProposal proposalAddress;
        address proposalCreator;  
        string title; 
        uint256 budget; // 0 
        uint tokens; 
        uint numVotes; // 
        bool canceled;
        bool aproved;
        bool pendig;
        address[] participantAddress; 
        mapping(address => uint) votes; // estructura que guarda los votantes y el nunero de votos 
        uint posArray; 
    }

    address payable owner;
    Token token; 
    bool votingOpen; 
    uint tokenPrice; 
    uint totalBudget; 
    uint numParticipantes;
    uint numProposals; 
    uint maxTokensForSale;  

    bool lock; 

    mapping(uint => Proposal) private propuestas; 
    uint[] approvedProposals = new uint[](0); 
    uint[] signalingProposals = new uint[](0);
    uint[] pendigProposal = new uint[](0);   
    //mapping(address => bool) private participantes; //participantes si true existe | false no existe 
    address[] participantesTotales = new address[](0); 

    modifier onlyOwner(){
        require(msg.sender == owner, "Is not the owner"); 
        _; 
    }
    modifier isLock(){
        require(!lock, "Hay un executeProposal en curso"); 
        _; 
    }

    modifier onlyParticipant {
        require(isParticipant(msg.sender), "No existe participante");//modificar y comprobar si el participante existe 
        _; 
    }
    modifier NotexistParticipant {
        require(!isParticipant(msg.sender), "existe participante");//modificar y comprobar si el participante existe 
        _; 
    }

    modifier isOpen {
        require(votingOpen, "La votacion no esta abierta"); 
        _;
    }

    modifier notOpen {
        require(!votingOpen, "La votacion ya esta abierta"); 
        _;
    }

    modifier existePropuesta(uint id){
        require(propuestas[id].numVotes != 0, "Propuesta no existe"); 
        _;
    }

    modifier isTheCreator(uint id){
        require(propuestas[id].proposalCreator == msg.sender, "No es el creador de la propuesta"); 
        _;
    }


    modifier checkMaxToken(uint _value){
        require(token.totalSupply() + _value < maxTokensForSale , "La votacion no esta abierta"); 
        _;
    }

    function isParticipant(address _participant) internal view returns (bool){
        bool participant; 
        (participant, ) = getParticipante(_participant); 
        return participant; 
    }

    function openVoting(uint256 _budgetInicial) public onlyOwner notOpen{ 
        require(_budgetInicial > 0, "Prosupuesto inicial insuficiente"); // comprobamos que el prosupuesto inicial es suficiente 

        totalBudget = _budgetInicial; 
        votingOpen = true; // abrimos la botacion 

        // Transfer the initial budget to the contract address
        token.transferFrom(msg.sender, address(this), totalBudget); // pasamos fondos al contrato QuadratingVoting, quien crea el contrato es el orgien 
    }

    function addParticipant() public payable NotexistParticipant {
        //Comprobar si el participante ya esta registrado TODO

        require(msg.value >= tokenPrice, "El importe enviado no es suficiente para comprar al menos un token");

        //aqui obtenemos el token
        uint256 tokensBought = msg.value / tokenPrice;
        require(tokensBought <= maxTokensForSale, "No hay suficientes tokens disponibles para la venta");
        participantesTotales.push(msg.sender); 
        //participantes[msg.sender] = true;
        numParticipantes += 1; 
        maxTokensForSale -= tokensBought; //restamos los token comprados
        token.mint(tokensBought);
        //token.transferFrom(msg.sender, tokensBought); // Transferimos los tokens comprados al participante
    }


    function getParticipante(address partcipantAddress) internal view returns (bool, uint){
        bool isParticipante = false; 
        uint index = 0; 

        for(uint i = 0; i < participantesTotales.length; i++){
            if(participantesTotales[i] == partcipantAddress){
                isParticipante = true;
                index = i; 
                break; 
            }
        }

        return(isParticipante, index); 
    }

    function _deleteParticipantes(address deleteAddress) internal {
        uint index; 
        (, index) = getParticipante(deleteAddress); 
        require(index < participantesTotales.length, "Indice fuera de rango"); 
        
        participantesTotales[index] = participantesTotales[participantesTotales.length - 1];
        participantesTotales.pop(); 
    }

    function _removeParticipant() public onlyParticipant{
        _deleteParticipantes(msg.sender);
        numParticipantes -= 1; 

    }

    function addProposal(string memory _title, uint _budget, address _proposalAddress) public onlyParticipant isOpen returns (uint idProposa){
        
        require(_budget > 0, "Prosupuesto insuficiente"); 
        uint _numTokens = _budget / tokenPrice; // calculamos el numero de tokens que requiere la propuesta
        numProposals += 1; // incrementamos en uno -> numProposal = id de las propuestas
        uint posArrayAux;  

        // Dos opciones que sea _budget = 0 significa que es el tipo signaling en caso contrario sera del tipo financiacion 
        // estos arrays nos sirven para tener ubicadas las propuestas evitando tener que recorrer el mapa 
        if(_budget == 0){ 
            signalingProposals.push(numProposals); 
            posArrayAux = signalingProposals.length - 1; 
        }
        else{
            pendigProposal.push(numProposals); 
            posArrayAux = pendigProposal.length - 1;  
        }
        // agregamos la nueva propuesta al mapa de propuestas. 
        //propuestas[numProposals] = (IExecutableProposal(_proposalAddress), msg.sender, _title, _budget, _numTokens, 0, false, false, true, address(0), posArrayAux); 
    }

    function cancelProposal(uint id) public isOpen existePropuesta(id) isTheCreator(id) {
        require(!propuestas[id].pendig, "Propuesta aprovada o ya cancelada");
        propuestas[id].canceled = true;

        if(propuestas[id].budget == 0){
            deleteFromArray(signalingProposals,propuestas[id].posArray); 
        }
        else{
            deleteFromArray(pendigProposal,propuestas[id].posArray); 
        }

        devolverDinero(id); 
    }

    function deleteFromArray(uint[] storage array, uint index) internal {
        require(index < array.length, "Indice fuera de rango"); 
        
        array[index] = array[array.length - 1];
        propuestas[array[index]].posArray = index;  
        array.pop(); 

    }

    function devolverDinero(uint idPropuesta) internal {
        address[] memory addressParticipants = propuestas[idPropuesta].participantAddress; 

        for(uint i = 0; i < addressParticipants.length; i++){
            address participante = addressParticipants[i]; 
            uint numVotes = propuestas[idPropuesta].votes[participante];

            if(numVotes > 0){
                token.transfer(participante, numVotes**2); // numero de tokes = votos^2 
            } 
        }
    }


    function buyTokens() external payable onlyParticipant checkMaxToken(msg.value/tokenPrice) {
        require(msg.value >= tokenPrice, "Cantidad insuficiente"); // comprobamos que la cantidad introducida es un cantidad valida para para comprar al menos un token 
        token.mint(msg.value/tokenPrice); 
    }

    function sellTokens(uint tokensAmount) public onlyParticipant{
        require(token.balanceOf(msg.sender) >= tokensAmount, "No tienes suficientes tokens para vender"); 
        token.burn(msg.sender, tokensAmount); 
        payable(msg.sender).transfer(tokensAmount*tokenPrice); 

    }

    function getERC20() external view returns (Token){
        return token; 
    }

    function getPendingProposals() internal view isOpen returns (uint[] memory) {
        return pendigProposal; 

    }

    function getApprovedProposals() internal view isOpen returns (uint[] memory) {
        return approvedProposals; 

    }

    function getSignalingProposals() internal view isOpen returns (uint[] memory) {
        return signalingProposals;
    }

    function getProposalInfo(uint id) internal view isOpen returns (Proposal storage) {
        return propuestas[id]; 
    }

    function stake(uint idPropuesta, uint numVotos) public isOpen onlyParticipant {
        require(!propuestas[idPropuesta].canceled, "Propuesta cancelada"); 
        require(!propuestas[idPropuesta].aproved, "Propuesta ya aprobada"); 

        uint previusVotes = propuestas[idPropuesta].votes[msg.sender]; 
        uint newVotesPriceIntokens = ((previusVotes + numVotos) ** 2) - (previusVotes**2); // Total votes ^ 2 - previusVotes ^2 = cantidad de tokens que se necesita 

        token.transferFrom(msg.sender, address(this), newVotesPriceIntokens);
        propuestas[idPropuesta].votes[msg.sender] += numVotos; 
        propuestas[idPropuesta].tokens += newVotesPriceIntokens;
        propuestas[idPropuesta].numVotes += numVotos; 
    }

    function withdrawFromProposal(uint idPropuesta, uint numVotos) public isOpen {
        require(!propuestas[idPropuesta].canceled, "Propuesta cancelada"); 
        require(!propuestas[idPropuesta].aproved, "Propuesta ya aprobada");
        
        uint votosActuales = propuestas[idPropuesta].votes[msg.sender]; // si es cero significa que el votante no existe 

        require(votosActuales > 0, "No existe votante"); 
        require(votosActuales >= numVotos, "Votos insuficientes para devolver");
        uint withdrawTokens = (votosActuales**2) - (votosActuales - numVotos)**2;
        token.transfer(msg.sender, withdrawTokens);
        propuestas[idPropuesta].votes[msg.sender] -= numVotos;
        propuestas[idPropuesta].numVotes -= numVotos; 
        propuestas[idPropuesta].tokens -= withdrawTokens;     
    }

    function _checkAndExecuteProposal(uint idPropuesta)internal isLock returns (bool) {

        // Multiplicamos por 10 para evitar los floats del 0,2 
        uint budget = propuestas[idPropuesta].budget;
        uint tokens = propuestas[idPropuesta].tokens;
        uint votos = propuestas[idPropuesta].numVotes; 


        uint thereshold = (2 + (budget * 10) / (totalBudget * 10)) * (numParticipantes*10) + (pendigProposal.length*10); 

        if(totalBudget + (tokens * tokenPrice) >= budget){
            if(votos >= thereshold){
                lock = true; 
                propuestas[idPropuesta].aproved = true; 
        //IMPORTANTE

                //IExecutableProposal(payable(propuestas[idPropuesta].proposalAddress)).executeProposal{volue: budget, gas:100000}(idPropuesta, votos, budget);

                totalBudget += propuestas[idPropuesta].tokens * tokenPrice; 
                totalBudget -= budget;
                // delete from pendingProposals 
                deleteFromArray(pendigProposal, propuestas[idPropuesta].posArray); 
                approvedProposals.push(idPropuesta); 
                token.burn(address(this), tokens); // quemamos los tokens, quien autoriza es el contrato de quadratingVoting 
                lock = false; 
                return true; 
            }
        }
        return false; 
    }

    function closeVoting() public onlyOwner {

        votingOpen = false; 
        uint[] memory signalingProp = getSignalingProposals(); 
        uint[] memory pendigProp = getPendingProposals();  
        uint signalingLegth = signalingProposals.length; 
        uint idAux;
        for(uint i = 0; i < signalingLegth; i++){
            devolverDinero(signalingProp[i]);
        }
        executeSignalingProposal(); // las prouestas de tipo signaling son ejecutadas 

        for(uint j = 0; j < pendigProp.length; j++){
            devolverDinero(pendigProp[j]); 
        }
        owner.transfer(totalBudget); 
        // INicializar a cero todo 
        totalBudget = 0; 
        //eliminamos las propuestas 
        cleanMapping(approvedProposals);
        cleanMapping(signalingProposals);
        cleanMapping(pendigProposal);

        approvedProposals = new uint[](0); 
        signalingProposals = new uint[](0);
        pendigProposal = new uint[](0); 

        numParticipantes = 0; 
        numProposals = 0; 
    }

    function executeSignalingProposal() internal view{
        uint id; 
        uint numVotos; 
        uint actualBudget; 
        uint[] memory arraySignaling; 

        for(uint i = 0; i < arraySignaling.length; i++){
            id = arraySignaling[i]; 
            numVotos = propuestas[id].numVotes; 
            actualBudget = propuestas[id].budget; 

            //IExecutableProposal(payable(id)).executeProposal{volue: actualBudget, gas:100000}(id, numVotos, actualBudget);
        }

    }

    function cleanMapping(uint[] memory arrayPropuestas) internal {
        address[] memory arrayParticipantes;
        address participante;
        uint propuesta;   

        for(uint i = 0; i < arrayPropuestas.length; i++){
            propuesta = arrayPropuestas[i];
            arrayParticipantes = propuestas[propuesta].participantAddress; 
            for(uint j = 0; j < arrayParticipantes.length; j++){
                participante = arrayParticipantes[j]; 
                delete propuestas[propuesta].votes[participante];
            }
            delete propuestas[propuesta]; 
        }


    }










}