// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol"; 
import "@openzeppelin/contracts/security/PullPayment.sol"; 
import "@openzeppelin/contracts/security/Pausable.sol"; 
import "./IExecutableProposal.sol";
import "./Token.sol"; 


abstract contract Dao {

    // Enume y struct
    enum State { pending, approved, canceled}
    struct Proposal2 {
        string title; 
        string description; 
        uint256 budget;
        uint256 tokens; 
        uint256 numVotes;
        State estado;
        IExecutableProposal proposalAddress;
        address proposalCreator;
        address[] participantAddress;
        mapping(address => uint) votes;
    }

   
    mapping (address => bool) internal whitelisting; 
    
    Token token; 
    uint256 tokenPrice; 
    uint256 totalBudget; 
    uint256 numParticipants;
    uint256 maxTokensForSale;  
    uint256 numProposals;

    
    Proposal2[] internal propuestas2;

    // Modificadores
    modifier onlyParticipant {
        require(whitelisting[msg.sender], "No eres participante");
        _; 
    }
    modifier isTheCreator(uint id){
        require(propuestas2[id].proposalCreator == msg.sender, "No creaste la propuesta"); 
        _;
    }

    event executed(uint256 indexed proposalId, bool success);

    /// @notice Apertura del periodo de votacion
    /// @param _budgetInicial (uint256) Presupuesto inicial que se recibe en WEI
    function openVoting(uint256 _budgetInicial) external virtual;

    /// @notice Para inscribirse un nuevo participante
    function addParticipant() external payable virtual; 

    /// @notice Elimina participante
    function _removeParticipant() external virtual; 

    /// @notice Cualquier participante puede agregar propuestas
    /// @param _title (string) titulo de la propuesta
    /// @param _description (string) Descripcion de la propuesta
    /// @param _budget (uint) presupuesto necesario para llevar a cabo la propuesta(0 signaling) 
    /// @param _proposalAddress (address) contrato con interfaz ExecutableProposal que recibe el dinero
    /// @return idProposal (uint256) Id de la propuesta creada
    function addProposal(string calldata _title, string calldata _description, uint256 _budget, address _proposalAddress) external virtual returns (uint256 idProposal);

    /// @notice El creador de la propuesta puede cancelarla.
    /// @param _id (uint256)  Id de la propuesta que se cancela
    function cancelProposal(uint256 _id) external virtual;

    /// @notice Comprar tokens en base a los ethers
    function buyTokens() external payable virtual ;

    /// @notice Vender tokens no gastados
    /// @param _tokensAmount (uint256)
    function sellTokens(uint256 _tokensAmount) external virtual;

    /// @notice obtener el contrato del token que se usa para las votaciones
    /// @return Token (address) Direccion del token usado 
    function getERC20() external view virtual returns (Token); 

    /// @notice devuelve las propuestas pendientes
    /// @return (uint256[]) array con los ID de las propuestas pedientes
    function getPendingProposals() public view virtual returns (uint256[] memory);

    /// @notice devuelve las propuestas aprobadas
    /// @return (uint256[]) array con los ID de las propuestas aprobadas
    function getApprovedProposals() external view virtual returns (uint256[] memory); 

    /// @notice devuelve las propuestas de signaling
    /// @return (uint256[]) array con los ID de las propuestas aprobadas
    function getSignalingProposals() public view virtual returns (uint256[] memory); 

    /// @notice devuelve informacion de la propuesta según Id
    /// @param _id (uint256) Id de la propuesta de la que quiero conocer la informacion
    /// @return _title (Proposal) titulo de la propuesta
    /// @return _description (string) Descripción de la propuesta
    /// @return _budget (uint256) Presupuesto de la propuesta
    /// @return _ejecutable (address) contrato ejecutable con interfaz IExecutableProposal
    /// @return _id (uint256) Id de la propuesta. Igual al parametro de entrada
    function getProposalInfo(uint256 _id) external view virtual returns (string memory _title, string memory _description, uint256 _budget, address _ejecutable, uint256);

    /// @notice Realiza voto del participante que la llama
    /// @param _idPropuesta (uint256) Id de la propuesta a la que quieren votar
    /// @param _numVotos (uint256) Numero de votos con los que quiere votar
    function stake(uint256 _idPropuesta, uint256 _numVotos) external virtual; 

    /// @notice Retira votos de un participante. Devolviendo el valor correspondiente al calculo cuadratico
    /// @param _idPropuesta (uint256) Identificador de la propuesta a la que quieren sacar votos.
    /// @param _numVotos (uint256) Cantidad de votos que quieren sacar.
    function withdrawFromProposal(uint256 _idPropuesta, uint256 _numVotos) external virtual; 

    /// @notice Para una propuesta: comprueba condiciones y ejecuta executeProposal(gas max=100000) transfiriendo el budget. Actualizar budgets y eliminar tokens del dinero transferido. 
    /// @param _idPropuesta (uint256) Id de la propuesta
    /// @return _Success (bool) True si fue bien, false si fracasa
    function _checkAndExecuteProposal(uint256 _idPropuesta) internal virtual returns (bool);

    /// @notice Solo el Owner puede cerrar la votacion, ejecutar signaling, descartando las propuestas no aprobadas y devolver tokens
    /// @return _success (bool) True si fue bien, false si fracasa
    function closeVoting() external virtual returns(bool _success); // “Favor pull over push.” => Evita DOS attacks
 
    /// @notice Funcion interna para saber si un participante esta registrado. Si no está registrado no podrá participar
    /// @param _participant (address) addres del participante que queremos comprobar
    /// @return _Success (bool) True si esta registrado, false si no lo esta
    function isParticipant(address _participant) internal view returns (bool){
        return whitelisting[_participant];
    } 
}


contract QuadraticVoting is Ownable, ReentrancyGuard, Pausable, Dao {

    /// @notice Constructor inicializa los parametros iniciales y crea el token ERC20
    /// @param _tokenPrice (uint256) Precio del token
    /// @param _maxTokensForSale (uint256) Cantidad máxima que tendrá el totalSupply del token.
    constructor(uint256 _tokenPrice, uint256 _maxTokensForSale) payable {
        _pause();
        if(_tokenPrice!=0) {
            tokenPrice = _tokenPrice;
        } else {
            tokenPrice=1;
        }
        if(_maxTokensForSale!=0) {
            maxTokensForSale = _maxTokensForSale;
        } else {
            maxTokensForSale = 1000000;
        }
        token = new Token();
    }

    //Solo Owner lo puede ejecutar y cuando está pausado. Se despausa y comienza a funcionar
    function openVoting(uint256 _budgetInicial) external override onlyOwner whenPaused { 
        require(_budgetInicial != 0, "Budget inicial insuficiente");
        totalBudget = _budgetInicial; 
        token.transferFrom(msg.sender, address(this), _budgetInicial); 
        _unpause();// abrimos la Votacion 
    }

    function addParticipant() external override payable {
        require(!isParticipant(msg.sender), "Usted ya esta registrado");
        require(msg.value >= tokenPrice, "Importe insuficiente"); 
        uint256 tokensBought = msg.value / tokenPrice; // Cantidad de tokens
        require(tokensBought <= maxTokensForSale, "No quedan suficientes tokens");

        whitelisting[msg.sender]=true; // se le inscribe como participante
        unchecked { ++numParticipants; } // solo se realiza una vez por participante
        maxTokensForSale -= tokensBought; 

        token.mint(msg.sender,tokensBought);
    }

    function _removeParticipant() external override onlyParticipant{
        whitelisting[msg.sender]=false;
        unchecked { --numParticipants; } // solo se hace 1 vez por cada participante inscrito(imposible que suceda underflow)
    }

    function addProposal(string calldata _title, string calldata _description, uint256 _budget, address _proposalAddress) public override onlyParticipant whenNotPaused returns (uint256 idProposal){
        uint256 _id=numProposals; // trabajamos desde memory

        propuestas2.push();
        propuestas2[_id].title=_title;
        propuestas2[_id].description=_description;
        propuestas2[_id].budget=_budget;
        propuestas2[_id].proposalAddress=IExecutableProposal(_proposalAddress);
        propuestas2[_id].proposalCreator=msg.sender;
        numProposals = _id + 1; // Incremento el Id de la propuesta
        return _id;
    }

    function cancelProposal(uint256 _id) external override whenNotPaused isTheCreator(_id) {
        if(devolverDinero(_id)==false) {// dentro de devolverDinero el estado cambia a cancelada
            revert("no se puede cancelar");
        }
    }

    function devolverDinero(uint256 _idPropuesta) internal returns(bool _success) {
        if(propuestas2[_idPropuesta].estado!=State.pending) {// verifico que siga pendiente
            return false;
        }
        propuestas2[_idPropuesta].estado= State.canceled; // si sigue pendiente la cancelo para que no vuelva a entrar
        uint256 arraySize=propuestas2[_idPropuesta].participantAddress.length;
        address addressParticipant; 
        uint256 numVotes; 
        while(arraySize!=0) { 
            unchecked { arraySize--; } // hacemos unchecked ya que si llega a 0 no entro en el while y no puede existir underflow
            addressParticipant=propuestas2[_idPropuesta].participantAddress[arraySize];
            numVotes = propuestas2[_idPropuesta].votes[addressParticipant];
            if(numVotes != 0){ 
                propuestas2[_idPropuesta].votes[addressParticipant]=0; 
                token.transfer(addressParticipant, numVotes*numVotes); // numero de tokes = votos^2 
            } 
            propuestas2[_idPropuesta].participantAddress.pop(); // elimino al participante de la lista
        }
        propuestas2[_idPropuesta].numVotes=0;
        return true;
    }

    function buyTokens() external payable override onlyParticipant {
        uint256 _tokensBought = msg.value / tokenPrice; // numero de tokens a comprar
        require(_tokensBought != 0, "Cantidad insuficiente"); // Al menos compramos 1 token
        maxTokensForSale -= _tokensBought; //restamos los token a comprar por los maximos token en venta. Si quiero comprar mas de los que hay en venta el underflow lo revierte
        token.mint(msg.sender,_tokensBought); 
    }

    function sellTokens(uint _tokensAmount) external override onlyParticipant nonReentrant {
        token.burnFrom(msg.sender, _tokensAmount); //burnFrom comprueba que tenga los token
        maxTokensForSale += _tokensAmount;
        payable(msg.sender).transfer(_tokensAmount*tokenPrice); 
    }

    function getERC20() external view override returns (Token){
        return token; 
    }

    function getPendingProposals() public view override whenNotPaused returns (uint256[] memory) {
        return _getPendingProposals();
    }

    
    function _getPendingProposals() private view returns (uint256[] memory) {
        uint256 arraySize= propuestas2.length;
        uint256 k;
        uint256[] memory _propuestasAux= new uint[](arraySize);
        while(arraySize!=0) {
            unchecked { --arraySize; }
            if(propuestas2[arraySize].budget!=0)
            {
                if(propuestas2[arraySize].estado==State.pending) {
                    _propuestasAux[k]=arraySize;
                    unchecked { ++k; } 
                }
            }
        }
        uint256[] memory _propuestas= new uint[](k);
        while(k!=0) {
            unchecked { --k; } // k no puede ser menos de 0 al comprobarlo en el while por lo que no puede ocurrir underflow
            _propuestas[k]=_propuestasAux[k];
        }
        return _propuestas; 
    }

    function getApprovedProposals() external view override whenNotPaused returns (uint256[] memory) {
        uint256 arraySize= propuestas2.length;
        uint256 k;
        uint256[] memory _propuestasAux= new uint[](arraySize);
        while(arraySize!=0) {
            unchecked { --arraySize; }
            if(propuestas2[arraySize].budget!=0)
            {
                if(propuestas2[arraySize].estado==State.approved) {
                    _propuestasAux[k]=arraySize;
                    unchecked { ++k; }
                }
            }
        }
        uint256[] memory _propuestas= new uint[](k);
        while(k!=0) {
            unchecked { --k; } // k no puede ser menos de 0 al comprobarlo en el while por lo que no puede ocurrir underflow
            _propuestas[k]=_propuestasAux[k];
        }
        return _propuestas; 
    }

    function getSignalingProposals() public view override whenNotPaused returns (uint256[] memory) {
        return _getSignalingProposals();
    }

    function _getSignalingProposals() private view returns (uint256[] memory) {
        uint256 arraySize= propuestas2.length;
        uint256 k;
        uint256[] memory _propuestasAux= new uint[](arraySize);
        while(arraySize!=0) {
            unchecked { --arraySize; }
            if(propuestas2[arraySize].budget==0) {
                _propuestasAux[k]=arraySize;
                unchecked { ++k; } 
            }
        }
        uint256[] memory _propuestas= new uint[](k);
        while(k!=0) {
            unchecked { --k; } // k no puede ser menos de 0 al comprobarlo en el while por lo que no puede ocurrir underflow
            _propuestas[k]=_propuestasAux[k];
        }
        return _propuestas; 
    }
    
    function getProposalInfo(uint256 _id) external view override whenNotPaused returns (string memory _title, string memory _description, uint256 _budget, address _ejecutable, uint256) {
        _title = propuestas2[_id].title; 
        _description = propuestas2[_id].description; 
        _budget = propuestas2[_id].budget; 
        _ejecutable = address(propuestas2[_id].proposalAddress); 
        return (_title, _description, _budget, _ejecutable, _id);
    }

    function stake(uint256 idPropuesta, uint256 numVotos) external override whenNotPaused onlyParticipant {
        require(propuestas2[idPropuesta].estado==State.pending, "Propuesta no pendiente"); 
        uint256 previusVotes = propuestas2[idPropuesta].votes[msg.sender]; 
        uint256 newVotes = previusVotes + numVotos; 
        uint256 newVotesPriceIntokens = newVotes*newVotes - previusVotes*previusVotes ; // Total votes ^ 2 - previusVotes ^ 2 = cantidad de tokens necesarios
        
        propuestas2[idPropuesta].votes[msg.sender] = newVotes; 
        unchecked { 
            propuestas2[idPropuesta].tokens += newVotesPriceIntokens; // no hay que checkear el overflow ya que  transferFrom nos asegura que no puedan transferirse más token de los existentes y tampoco underflow porque no puedo mandar numeros negativos
            propuestas2[idPropuesta].numVotes += numVotos; 
        }
        if(previusVotes==0) {
            propuestas2[idPropuesta].participantAddress.push(msg.sender);
        }
        token.transferFrom(msg.sender, address(this), newVotesPriceIntokens); // si el transferFrom falla lo anterior se revierte
        _checkAndExecuteProposal(idPropuesta);
    }

    function withdrawFromProposal(uint256 idPropuesta, uint256 numVotos) external override whenNotPaused {
        require(propuestas2[idPropuesta].estado==State.pending, "Propuesta no pendiente"); 
        uint256 previusVotes = propuestas2[idPropuesta].votes[msg.sender]; 
        require(previusVotes != 0, "No existe votante"); 
        uint256 newVotes = previusVotes - numVotos; 
        uint256 withdrawTokens = previusVotes*previusVotes - newVotes*newVotes;
        
        propuestas2[idPropuesta].votes[msg.sender] = newVotes;
        unchecked { 
            propuestas2[idPropuesta].numVotes -= numVotos; // antes se asegura que pueda retirar este numero de votos
            propuestas2[idPropuesta].tokens -= withdrawTokens; // y estos tokens. Por lo que no tiene sentido corroborarlo  
        }
        
        token.transfer(msg.sender, withdrawTokens);
    }

    //antes de hacer cualquier cosa cambio el estado a approved y es lo primero que se checkea haciendo ya de lock por lo que el lock para no reentrant no tiene sentido 
    function _checkAndExecuteProposal(uint idPropuesta) internal override returns (bool) {
        if(propuestas2[idPropuesta].estado==State.approved) {
            return false; 
        }
        
        uint256 _budget = propuestas2[idPropuesta].budget;
        if(_budget==0) { 
            return false;
        }
        uint256 _pretotalBudget = totalBudget;
        uint256 _tokens = propuestas2[idPropuesta].tokens;
        uint256 _totalBudget = _pretotalBudget + (_tokens * tokenPrice);
        if(_totalBudget < _budget) {
            return false;
        }
        
        uint256 _votos = propuestas2[idPropuesta].numVotes; 
        //Multiplicamos *10 para evitar los floats
        uint256 _theresholdx10 = (2 + (_budget*10) / _pretotalBudget)*numParticipants + getPendingProposals().length*10;
        if( (10*_votos) >= _theresholdx10 ){
            
            propuestas2[idPropuesta].estado=State.approved; // la cambio a aprobada y asi evito reentrancia
            unchecked { 
                _totalBudget -= _budget; 
                maxTokensForSale += _tokens; 
            } 
            totalBudget = _totalBudget; 
            token.burn(_tokens); // quemamos los tokens
            // Ejecuto la propuesta
            try propuestas2[idPropuesta].proposalAddress.executeProposal{value: _budget, gas: 100000}(idPropuesta, _votos, _tokens) {
                emit executed(idPropuesta, true); // en el caso de que se logre ejecutar
            } catch {
                emit executed(idPropuesta, false); // en el caso de que no se ejecute
            }
            
            return true; 
        }
        return false; 
    }

    
    function closeVoting() external override onlyOwner nonReentrant returns(bool _success){
        _pause(); //pausamos la votacion 
        uint256[] memory signalingProp = _getSignalingProposals(); 
        uint256[] memory pendingProp = _getPendingProposals();  
        uint256 signalingLegth = signalingProp.length; 
        uint256 pendingLegth = pendingProp.length; 
        //indice menos y maximo de las propuestas
        uint256 _menor;
        uint256 _mayor;
        uint256 i;
        uint256 _gasCheck;
        uint8 flag; 
        
        if(signalingLegth<pendingLegth) {
            (_menor,_mayor)=(signalingLegth,pendingLegth);
            flag=1; 
        } else {
            (_menor,_mayor)=(pendingLegth,signalingLegth);
        }
        for(; i < _menor; i++){ // Se ejecutan 2 por loop
            _gasCheck=gasleft();
            devolverDinero(signalingProp[i]);
            devolverDinero(pendingProp[i]); 

            try propuestas2[signalingProp[i]].proposalAddress.executeProposal{gas: 100000}(signalingProp[i], propuestas2[signalingProp[i]].numVotes, propuestas2[signalingProp[i]].tokens) {
                emit executed(signalingProp[i], true); // en el caso de que se logre ejecutar
            } catch {
                emit executed(signalingProp[i], false); // en el caso de que no se logre ejecutar
            }
           _gasCheck=_gasCheck-gasleft();
            if(gasleft()<(_gasCheck<<1)) { 
                // si el gas que tiene ahora es menor al doble de gas que uso para una vuelta(para tener un margen de seguridad) 
                //terminamos la funcion pero sin revertir para que podamos volver a ejecutar esta funcion y proseguir desde donde nos quedamos en esa ejecucion
                return false;
            }
        }
        if(flag==0) {
            while(i<signalingLegth) {
                _gasCheck=gasleft();
                devolverDinero(signalingProp[i]);
                
                try propuestas2[signalingProp[i]].proposalAddress.executeProposal{gas: 100000}(signalingProp[i], propuestas2[signalingProp[i]].numVotes, propuestas2[signalingProp[i]].tokens) {
                    emit executed(signalingProp[i], true); // en el caso de que se logre ejecutar
                } catch {
                    emit executed(signalingProp[i], false); // en el caso de que no se logre ejecutar 
                }
                unchecked {i++;}
                _gasCheck=_gasCheck-gasleft();
                if(gasleft()<(_gasCheck<<1)) {
                    // si el gas que tiene ahora es menor al doble de gas que uso para una vuelta(para tener un margen de seguridad) 
                    //terminamos la funcion pero sin revertir para que podamos volver a ejecutar esta funcion y proseguir desde donde nos quedamos en esa ejecucion
                    return false;
                }
            }
        } else {
            while(i<pendingLegth) {
                _gasCheck=gasleft();
                devolverDinero(pendingProp[i]);
                unchecked {i++;}
                _gasCheck=_gasCheck-gasleft();
                if(gasleft()<(_gasCheck<<1)) {
                    // si el gas que tiene ahora es menor al doble de gas que uso para una vuelta(para tener un margen de seguridad) 
                    //terminamos la funcion pero sin revertir para que podamos volver a ejecutar esta funcion y proseguir desde donde nos quedamos en esa ejecucion
                    return false;
                }
            }
        }
        
        // quemo los tokens del contrato
        token.burn(token.balanceOf(address(this)));
        //veo cuantos tokens quedan
        uint256 _tokenTotalSuply=token.totalSupply();
        //calculo cuanto dinero tengo que dejar en el contrato para que la gente pueda vender sus tokens
        uint256 _otherPeoplesMoney = _tokenTotalSuply*tokenPrice;
        // calculo el dinero que el owner puede sacar del contrato
        uint256 ownersMoney = address(this).balance - _otherPeoplesMoney;
        payable(msg.sender).transfer(ownersMoney); 
        // Inicializo el numero de propuestas a 0. El resto ya se borro al devolver o se sobrescribe al crearla en la siguiente votacion por lo que no tiene sentido borrarlas
        numProposals = 0; 
        delete propuestas2;
        return true;
    }

}