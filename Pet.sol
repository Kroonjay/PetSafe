import "./PetStatus.sol";
import "./PetRegistry.sol";

contract Pet {

    bytes32 public identifier; //Hash of Secret Number embedded on pet tag

    address private owner;

    address private keeper; //Same as owner when status == Safe, unset when lost, set to finder when found

    PetStatus public status;

    Registry private registry;

    modifier isOwner() {
        require(msg.sender == owner, "Caller is Not Owner");
        _;
    }

    modifier isSafe(){
        require(status == PetStatus.Safe, "Pet Not Safe");
        _;
    }

    modifier isLost(){
        require(status == PetStatus.Lost, "Pet Not Lost");
        _;
    }


    constructor(bytes32 _identifier, address _owner, address _registry){
        // identifier = keccak256(abi.encodePacked(_identifier));
        identifier = _identifier;
        owner = _owner;
        registry = Registry(_registry);
    }
    //TODO Add Reward Mechanism
    function lost() public isOwner isSafe returns (bool success){
        bool didRegister = registry.addLostPet();
        if (!didRegister){
            revert("Failed to Update Registry!");
        }
        status = PetStatus.Lost;
        delete keeper; //Unset keeper as pet is presumed lost
    }

    function found(uint _identifier) public isLost {
        bytes32  _identifierHash = keccak256(abi.encodePacked(_identifier));
        if(_identifierHash != identifier){
            revert ("Invalid Identifier!");
        }
        bool didRegister = registry.removeLostPet();
        if (!didRegister){
            revert("Failed to Update Registry!");
        }
        status = PetStatus.Found;
        keeper = msg.sender; //Set keeper to caller with valid identifier, identifier is considered "burned"
    }

}