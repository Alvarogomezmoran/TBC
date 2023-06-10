# TBC-Project-


Memoria del Proyecto Gobernanza y Sistemas de Votación

Tecnología Blockchain y Smart Contracts
  

QuadraticVoting.sol
  Estructura Proposal:

  Esta estructura representa una propuesta dentro del contrato. Contiene lso siguientes campos:
      •	"proposalAddress": Es una dirección que apunta a un contrato ejecutable que implementa una propuesta específica.
      •	"proposalCreator": Es la dirección del creador de la propuesta.
      •	"title": Es el título de la propuesta.
      •	"budget": Es el presupuesto asignado a la propuesta.
      •	"tokens": Es la cantidad de tokens asociados a la propuesta.
      •	"numVotes": Es el número de votos recibidos para la propuesta.
      •	"canceled": Booleano que muestra si la propuesta ha sido cancelada.
      •	"aproved": Booleano que muestra si la propuesta ha sido aprobada.
      •	"pendig": Booleano que muestra si la propuesta está pendiente.
      •	"participantAddress": Es un array de direcciones que almacena las direcciones de los participantes en la propuesta.
      •	"votes": Es un mapa que guarda los votantes y el número de votos que han emitido para esta propuesta.
      •	"posArray": Posición en el array de los distintos tipos de propuestas evitamos así tener que recorrer el array para operaciones como            el borrado.

Mapas y Arrays:
      •	"propuestas": Es un mapa que asigna un identificador único a cada propuesta.
      •	"approvedProposals": Es un array dinámico que almacena los identificadores de las propuestas aprobadas.
      •	"signalingProposals": Es un array que almacena los identificadores de las propuestas de tipo signaling.
      •	"pendigProposal": Es un array que almacena los identificadores de las propuestas pendientes.
      •	"participantesTotales": Es un array que almacena las direcciones de todos los participantes en el contrato.
Modificadores:

1.	Modifier "onlyOwner":
      •	Descripción: Este modificador restringe el acceso a una función sólo al propietario del contrato.
      •	Uso: Se utiliza antes de una función para asegurarse de que solo el propietario pueda llamar a dicha función.
      •	Funcionalidad: Verifica si el remitente del mensaje (msg.sender) es igual al propietario registrado en la variable "owner". Si no es el propietario, la función genera una excepción y no se ejecuta. Si el remitente es el propietario, la función se ejecuta normalmente.
      
2.	Modifier "isLock":
      •	Descripción: Este modificador se utiliza para verificar si el contrato está bloqueado.
      •	Uso: Se utiliza antes de una función para asegurarse de que no haya una ejecución de propuesta en curso.
      •	Funcionalidad: Verifica si la variable booleana "lock" es falsa. Si es verdadera, se genera una excepción y la función no se ejecuta. Si es falsa, la función se ejecuta normalmente.
      
3.	Modifier "onlyParticipant":
      •	Descripción: Este modificador restringe el acceso a una función solo a los participantes registrados en el contrato.
      •	Uso: Se utiliza antes de una función para asegurarse de que solo los participantes registrados puedan llamarla.
      •	Funcionalidad: Verifica si el remitente (msg.sender) es un participante registrado llamando a la función interna "isParticipant". Si el remitente no es un participante, se genera una excepción y la función no se ejecuta. Si el remitente es un participante, la función se ejecuta normalmente.
    
4.	Modifier "NotexistParticipant":
      •	Descripción: Este modificador restringe el acceso a una función solo si el remitente no es un participante registrado en el contrato.
      •	Uso: Se utiliza antes de una función para asegurarse de que el remitente no sea un participante registrado.
      •	Funcionalidad: Verifica si el remitente (msg.sender) no es un participante registrado llamando a la función interna "isParticipant". Si el remitente es un participante, se genera una excepción y la función no se ejecuta. Si el remitente no es un participante, la función se ejecuta normalmente.
      
5.	Modifier "isOpen":
      •	Descripción: Este modificador se utiliza para verificar si la votación está abierta.
      •	Uso: Se utiliza antes de una función para asegurarse de que la votación esté abierta antes de realizar una operación específica.
      •	Funcionalidad: Verifica si la variable booleana "votingOpen" es verdadera. Si es falsa, se genera una excepción y la función no se ejecuta. Si es verdadera, la función se ejecuta normalmente.
      
6.	Modifier "existePropuesta":
      •	Descripción: Este modificador se utiliza para verificar si una propuesta con el identificador especificado existe en el contrato.
      •	Uso: Se utiliza para asegurarse de que la propuesta exista antes de realizar una operación específica.
      •	Funcionalidad: Verifica si el número de votos de la propuesta con el identificador "id" en el mapping "propuestas" es diferente de cero. Si es cero, se genera una excepción y la función no se ejecuta. Si no es cero, la función se ejecuta normalmente.
      
7.	Modifier "isTheCreator":
      •	Descripción: Este modificador se utiliza para verificar si el remitente es el creador de una propuesta específica.
      •	Uso: Se utiliza antes de una función para asegurarse de que el remitente sea el creador de la propuesta antes de realizar una operación específica.
      •	Funcionalidad: Verifica si la dirección del remitente del mensaje (msg.sender) coincide con la dirección del creador de la propuesta con el identificador "id" en el mapping "propuestas". Si las direcciones no coinciden, se genera una excepción y la función no se ejecuta. Si las direcciones coinciden, la función se ejecuta normalmente.
      
8.	Modifier "checkMaxToken":
    •	Descripción: Este modificador se utiliza para verificar si la suma de un valor específico al suministro total de tokens no superará el límite máximo de tokens disponibles para la venta.
    •	Uso: Se utiliza antes de una función para asegurarse de que no se exceda el límite de tokens disponibles antes de realizar una operación específica.
    •	Funcionalidad: Verifica si la suma del suministro total de tokens actual en el contrato y el valor "_value" es menor que el límite máximo de tokens para la venta especificado en la variable "maxTokensForSale". Si se supera el límite, se genera una excepción y la función no se ejecuta. Si no se supera el límite, la función se ejecuta normalmente.

Funciones:
•	openVoting:
  •	Descripción: Esta función se utiliza para abrir la votación en el contrato, establecer el presupuesto inicial y transferir los fondos iniciales al contrato.
  •	Modificadores:
    •	onlyOwner
    •	notOpen
  •	Funcionalidad:
    •	Verifica si el presupuesto inicial especificado es mayor que cero. Si no lo es, se genera una excepción y la función se detiene.
    •	Asigna el valor del presupuesto inicial a la variable totalBudget.
    •	Establece la variable booleana votingOpen en true, lo que indica que la votación está abierta.
    •	Transfiere los fondos iniciales desde el remitente (msg.sender) al contrato QuadratingVoting utilizando la función transferFrom del contrato de token token.
    
•	addParticipant:
  •	Descripción: Esta función se utiliza para agregar un participante al contrato. El participante debe enviar un importe suficiente para comprar al menos un token y no debe estar registrado previamente como participante.
  •	Modificaciones:
    •	NotexistParticipant
  •	Funcionalidad:
    •	Verifica si el remitente del mensaje no está registrado previamente como participante. Si lo está, se genera una excepción y la función se detiene.
    •	Verifica si el importe enviado por el remitente es mayor o igual al precio de un token. Si no lo es, se genera una excepción y la función se detiene.
    •	Calcula la cantidad de tokens que se pueden comprar dividiendo el valor de msg.value por el precio de un token.
    •	Verifica si la cantidad de tokens comprados no supera la cantidad máxima de tokens disponibles para la venta. Si la supera, se genera una excepción y la función se detiene.
    •	Agrega la dirección del remitente (participante) al array participantesTotales..
    •	Incrementa el contador numParticipantes en 1.
    •	Resta la cantidad de tokens comprados de la variable maxTokenForSale.
    •	Llama a la función mint del contrato token para crear los tokens comprados y asignarlos al remitente (participante).
    
•	getParticipante: 
  •	Descripción: sirve para buscar un participante en caso de que exista devuelve dos valores, un booleano, true en caso de que esté, false en caso contrario. En caso de que exista también devuelve el índice del array donde está.
  
•	_deleteParticipantes: 
  •	Descripción: esta función auxiliar es la encargada de eliminar a un participante del array. 

•	_removeParticipant: 
  •	Descripción: función pública que elimina a un participante siempre y cuando sea él quien llame a esta función 
  •	Modificadores: 
    •	OnlyParticipant 

•	addProposal: 
  •	Descripción: dado los datos necesarios para añadir una propuesta que son pasados por parámetro crea una nueva propuesta. 
  •	Modificadores: 
    •	OnlyParticipant
    •	isOpen
  •	Funcionalidad: 
    •	Comprobamos que quien quere añadir una propuesta es un participante registrado además de comprobar que la votación está abierta. 
    •	Se hace comprobaciones de los argumentos para determinar si son válidos.
    •	Distinguimos si es una propuesta de financiación o signaling para almacenarla donde corresponde. 
    •	Creamos la propuesta en storage ya que usamos una estructura donde no se puede crear en memoria. 
    •	Asignamos los valores a la propuesta. 
    
•	cancelProposal: 
  •	Descripción: dado un id de propuesta cancela la propuesta, la elimina de las estructuras almacenadas además de devolver el dinero a los votantes
  •	Modificadores: 
    •	isOpen
    •	existePropuesta(id)
    •	isTheCreator(id)
  •	Funcionalidad: 
    •	Comprobamos primero que la votación está abierta, es una propuesta válida y que la propuesta corresponde con quién llama a la función. 
    •	Asignamos a la propuesta como cancelada ya que la mantenemos en el mapa de propuestas. 
    •	la borramos de los arrays que distinguen los dos tipos de propuestas. 
    •	Llamamos a la función “devolverDinero” que dado el id de propuesta devuelve el dinero a sus votantes. 
    •	Finalmente, eliminamos la propuesta del mapa 
    
•	deleteFromArray: 
  •	Descripción: función auxiliar que permite borrar de un array, dado un array y un índice. 
  
•	devolverDinero: 
  •	Descripción: devuelve el dinero a los votantes de la propuesta, es una función interna
  •	Funcionalidad: 
    •	Dada una propuesta guardamos en memoria el array de votantes ya que lo tenemos que recorrer. 
    •	transferimos los tokens correspondientes a cada votante. 
    
•	buyTokens: 
  •	Descripción: permite a un participante registrado comprar tokens 
  •	Modificadores: 
    •	OnlyParticipant
    •	checkMaxToken 
  •	Funcionalidad: 
    •	Comprobamos que quien llama es un participante previamente registrado además se comprueba que no se excede el número máximo de tokens. 
    •	Verificamos que el participante ha ingresado una cantidad suficiente para comprar al menos un token 
    •	Finalmente llamamos a la función mint del contrato Token que se encarga de crear y darle los tokens al usuario. 

•	sellTokens: 
  •	Descripción: función opuesta a buyTokens, intercambia los tokens por ether
  •	Modificadores: 
    •	OnlyParticipant
  •	Funcionalidad:
    •	Comprobamos que es participaonte registrado
    •	Verificamos que su balance es suficiente para vender la cantidad de tokens que ha indicado. 
    •	quemamos esa cantidad de tokens 
    •	transferimos los fondos al usuario
    
•	getERC20: 
  •	Descripción: devuelve el tipo de datos “Token” que es un contrato por lo que es la dirección

•	getPendingProposals: 
  •	Descripción: devuelve el array de pendingProposals guardándolo en memory.

•	getApprovedProposals: 
  •	Descripción: devuelve el array de approvedProposals guardándolo en memory. 

•	getSignalingProposals: 
  •	Descripción: devuelve el array de signalingProposals guardándolo en memory. 

•	getProposalInfo: 
  •	Descripción: dado un id devuelve una propuesta, dado que tipo de datos Proposal tiene un mapa se debe devolver en storage. 

•	stake: 
  •	Descripción: esta función engloba la lógica de la acción de votar. 
  •	Modificadores: 
    •	isOpen
    •	OnlyParticipant
  •	Funcionalidad: 
    •	Comprobamos que la votación está abierta, además se necesita saber que se es participante. 
    •	Verificamos que la propuesta no está cancelada ni ha sido aprobada.
    •	calculamos el número de tokens que corresponde con los votos en función de la fórmula cuadrática. 
    •	Transferimos los tokens del usuario al contrato de quadratingVoting con la función transferFrom
    •	Nota: para realizar la transferencia de votos necesitamos el permiso “allowance” no aparece aquí la comprobación porque está dentro de la función transferFrom que llama a la función del ERC20 spendAllowance
    •	Actualizamos datos en la propuesta como, votos, tokens y número de votos del usuario que ha realizado la votación.

•	withdrawFromProposal:
  •	Descripción: acción opuesta a stake, es decir, retira un voto de una propuesta
  •	Modificadores: 
    •	isOpen 
  •	Funcionalidad: 
    •	La votación ha de estar abierta 
    •	La propuesta ha de estar pendiente, ni cancelada ni aprobada. 
    •	hacemos comprobación de que existe votante y que los votos son suficiente con lo que ha pedido retirar
    •	Se calculan los tokens que se necesita para el número de votos solicitado.
    •	Se transfieren del contrato que los custodia al usuario
  •	Se actualiza la información 

•	_checkAndExecuteProposal: 
  •	Descripción: función que comprueba si una propuesta reúne todas las condiciones para poder ser aprobada
  •	Modificadores: onlyOwner
  •	Funcionalidad: 
    •	Solo el creador puede ejecutar esta función.
    •	En este proceso tenemos una sección cítrica la cual hay que proteger para que los datos no sean accedidos por otra llamada haciendo que se  actualicen sin que la llamada previa lo sepa. Esto podría desencadenar un posible ataque de reentracy por llamas a la función executeProposal.
    •	Para evitar este ataque usamos un lock que es una variable booleana que permite el acceso a la sección crítica evitando la carrera de datos. 
    •	Verificamos si el presupuesto recaudado más el presupuesto total es mayor o igual que lo que requiere la propuesta
    •	Cálculo del umbral threshold, dado que no se puede operar con número reales, solo con enteros. Para poder hacer la operación con “0,2” multiplicamos toda la expresión por 10 consiguiendo que 0,2 sea 2 (número entero) y como todo lo demás está multiplicado por 10 son expresiones equivalentes. 
    •	Una vez hayamos verificado que todo está bien, ponemos la propuesta como aprobada. 
    •	Ejecutamos dicha propuesta mediante la llamada a la función executeProposal de la interfaz IExecutableProposal
    •	Actualizamos el presupuesto total, sumando lo recaudado por la propuesta, pero a su vez se decrementa por el budget que se envía al contrato de la propuesta.
    •	Dado que llevamos un array con las propuestas aprobadas se añade también ahí y se elimina de las pendientes. 
    •	Finalmente, quemamos los tokens destinados a la propuesta 
    •	Abrimos el lock ya que hemos terminado y ya no existen riesgos. 

•	closeVoting: 
  •	Descripción: cierra la votación, devuelve los tokes de propuestas no aprobadas, en el caso de las propuestas de signaling las ejecuta y al owner se le transfiere el presupuesto restante. 
  •	Modificadores: 
    •	OnlyOwner
  •	Funcionalidad: 
    •	Ponemos la votación en cerrada, poniendo a false la variable votingOpen
    •	Devolvemos el dinero a los votantes de la propuesta signaling, para ello recorremos el array donde las tenemos almacenadas. 
    •	Posteriormente ejecutamos las propuestas de tipo signaling 
    •	Devolvemos el dinero a los votantes de las propuestas que están todavía pendientes. 
    •	Devolvemos el dinero sobrante al owner 
    •	Borramos las estructuras de mapping
    •	Inicializamos los arrays y las variables vinculadas al proceso de votación

•	executeSignalingProposal: 
  •	Descripción: función interna que ejecuta todas las propuestas del tipo signaling

•	cleanMapping: 
  •	Descripción: dado que almacenamos las propuestas en tres arrays distintos para tenerlas mejor ubicadas y para evitar recorrer el mapa filtrado cual es cual. Por lo tanto, la unión de los tres arrays nos da como resultado todas las propuestas. 
    •	Funcionalidad: 
    •	Debemos eliminar el mapa de votantes de cada propuesta para ello recorremos las propuestas eliminando cada votante para finalmente eliminar la propuesta. 
    •	Esta función es llamada tres veces por cada array de propuestas. 
