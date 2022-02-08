// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./PetRegistry.sol";

enum PetStatus{Unregistered, Safe, Lost, Found}

enum PetColor{ Unregistered, DarkBrown, LightBrown, Black, White, DarkGray, LightGray, Other}

enum PetMarking{ Unregistered, Spots, Stripes, Marble, Pure} //Pure will have secondary color==primary color, all others will have secondary color

enum PetType{ Unregistered, Dog, Cat }

enum PetTemperment{ Unregistered, Dangerous, Approachable }

library PetEngine {

    // https://blog.gnosis.pm/solidity-delegateproxy-contracts-e09957d0f201
    // we have to repeat the event declarations in the contract
    // in order for some client-side frameworks to detect them
    // (otherwise they won't show up in the contract ABI)

    event NameChanged(string oldName, string newName);
    event StatusChanged(PetStatus indexed oldStatus, PetStatus indexed newStatus);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner); //TODO Build support for this
    event KeeperChanged(address indexed oldKeeper, address indexed newKeeper);
    event RegistryChanged(address indexed oldRegistry, address indexed newRegistry);
    event ColorsChanged(PetColor indexed primaryColor, PetColor indexed secondaryColor, PetMarking indexed markings);

    struct PetDetails {
        string name;
        bool nameSet; //Easiest way to check if a string has been set 
        PetType petType;
        PetColor primaryColor;
        PetMarking markings;
        PetColor secondaryColor;
        PetTemperment temperment;
        uint256 dateOfBirth;
        uint weight; 
        uint8 homeLatitude; //Keeping this as an integer to limit precision (1 degree of latitude == 69 miles)
        uint8 homeLongitude;
        bool respondsToName;
    }


    struct PetStorage {
        address petSafe;
        address owner; //TODO Implement multi-sig ownership
        address keeper;
        bytes32 identifier;
        PetStatus status;
        Registry registry;
        PetDetails details;
    }

    modifier isUnregistered() {
        PetStorage storage ps = petStorage();
        require(ps.status == PetStatus.Unregistered, "Pet Already Registered");
        _;
    }



    function petStorage() internal pure returns (PetStorage storage ps) {
        bytes32 position = keccak256("diamond.standard.petsafe.pet.storage");
        assembly { ps.slot := position }
    }

    function setPetSafe(address _petSafe) internal {
        PetStorage storage ps = petStorage();
        ps.petSafe = _petSafe;
    }

    function getName() public view returns (string storage) {
        PetStorage storage ps = petStorage();
        return ps.details.name;
    }
    //TODO Add limits here
    function setName(string memory _name) internal isUnregistered {
        PetStorage storage ps = petStorage();
        emit NameChanged(ps.details.name, _name);
        ps.details.name = _name;
        ps.details.nameSet = true;
    }

    function setPetType(PetType _type) internal isUnregistered{
        PetStorage storage ps = petStorage();
        require(ps.details.petType == PetType.Unregistered, "Pet Type already Set");
        require(_type > PetType.Unregistered, "Pet Type Invalid");
        ps.details.petType=_type;
    }

    function getPetType() internal view returns (PetType) {
        PetStorage storage ps = petStorage();
        return ps.details.petType;
    }

    function setDateOfBirth(uint _dob) internal isUnregistered{
        PetStorage storage ps = petStorage();
        require(ps.details.dateOfBirth==0, "DoB Already Set!");
        ps.details.dateOfBirth=_dob;
    }

    function setOwner(address _owner) internal {
        PetStorage storage ps = petStorage();
        emit OwnerChanged(ps.owner, _owner);
        ps.owner = _owner;
    }

    function setPermDetails(PetType _petType, string memory _name, uint _dob) internal isUnregistered {
        setPetType(_petType);
        setName(_name);
        setDateOfBirth(_dob);
    }

    function getOwner() internal view returns (address) {
        PetStorage storage ps = petStorage();
        return ps.owner;
    }

    function setKeeper(address _keeper) internal {
        PetStorage storage ps = petStorage();
        emit KeeperChanged(ps.keeper, _keeper);
        ps.keeper = _keeper;
    }

    function getKeeper() internal view returns (address) {
        PetStorage storage ps = petStorage();
        return ps.keeper;
    }

    function setRegistry(address _registry) internal {
        PetStorage storage ps = petStorage();
        emit RegistryChanged(address(ps.registry), _registry);
        ps.registry = Registry(_registry);
    }

    function setColors(PetColor _primaryColor, PetColor _secondaryColor, PetMarking _markings) internal isUnregistered {
        PetStorage storage ps = petStorage();
        if(_markings == PetMarking.Pure){
            _secondaryColor=_primaryColor;
        }
        require(_primaryColor > PetColor.Unregistered, "Primary Color Invalid");
        require(_secondaryColor > PetColor.Unregistered, "Secondary Color Invalid");
        require(_markings > PetMarking.Unregistered, "Markings Invalid");
        ps.details.primaryColor=_primaryColor;
        ps.details.secondaryColor=_secondaryColor;
        ps.details.markings=_markings;
        emit ColorsChanged(ps.details.primaryColor, ps.details.secondaryColor, ps.details.markings);
    }
    
    function setHome(uint8 _homeLatitude, uint8 _homeLongitude) internal {
        require(_homeLatitude > 0, "Home Latitude Unset");
        require(_homeLongitude > 0, "Home Longitude Unset");
        require(_homeLatitude < 90, "Home Latitude Invalid"); //Max value for latitude is 90 degrees North or South
        require(_homeLongitude < 180, "Home Longitude Invalid"); //Max Value for longitude (Intl. Dateline)
        PetStorage storage ps = petStorage();
        ps.details.homeLatitude = _homeLatitude;
        ps.details.homeLongitude = _homeLongitude;
    }

    function setTemperment(PetTemperment _temperment, bool _respondsToName) internal {
        require(_temperment > PetTemperment.Unregistered, "Pet Temperment Unset");
        PetStorage storage ps = petStorage();
        ps.details.temperment = _temperment;
        ps.details.respondsToName = _respondsToName;
    }

    function canRegister() internal view returns (bool) {
        PetStorage storage ps = petStorage();
        require(ps.status==PetStatus.Unregistered, "Pet already Registered!");
        require(ps.details.nameSet, "Name is Unset but Required");
        require(ps.details.petType > PetType.Unregistered, "Pet Type is Unset but Required");
        require(ps.details.dateOfBirth > 0, "DoB is Unset but Required");
        require(ps.details.primaryColor > PetColor.Unregistered, "Primary Color is Unset but Required");
        require(ps.details.homeLatitude > 0, "Home Latitude is Unset but Required");
        require(ps.details.homeLongitude > 0, "Home Longitude is Unset but Required");
        return true;
    }

    function canLose() internal view returns (bool) {
        PetStorage storage ps = petStorage();
        require(ps.status==PetStatus.Safe, "Pet Not Safe!");
        require(ps.keeper==ps.owner, "Owner Keeper Mismatch!");//This should never happen
        require(ps.registry.isRegisteredPet(getHash()), "Pet Not Registered");
        return true;
    }

    function canFind() internal view returns (bool) {
        PetStorage storage ps = petStorage();
        require(ps.status==PetStatus.Lost, "Pet Not Lost!");
        require(ps.keeper != address(0), "Keeper is Unset but Required");
        require(ps.registry.isLostPet(), "Pet Not Lost in Registry");
        return true;
    }

    function statusChangeIsValid(PetStatus _newStatus) internal view returns (bool) {
        if(_newStatus == PetStatus.Unregistered){
            if(canRegister()){
                return true;
            }

        } else if(_newStatus == PetStatus.Safe){
            if(canLose()){
                return true;
            }
        } else if(_newStatus == PetStatus.Lost){
            if(canFind()){
                return true;
            }
        } else if(_newStatus == PetStatus.Found){
            return true; //TODO Add Identifier reset functionality here
        }
        return false;
    }

    function init(bytes32 _identifier, address _owner, address _registry) internal {
        PetStorage storage ps = petStorage();
        require(ps.status == PetStatus.Unregistered, "Pet already Registered!");
        
        ps.identifier=_identifier;
        setOwner(_owner);
        setKeeper(_owner);
        setRegistry(_registry);
    }

    function setStatus(PetStatus _status) internal {
        require(statusChangeIsValid(_status), "Invalid Status Change");
        PetStorage storage ps = petStorage();
        emit StatusChanged(ps.status, _status);
        ps.status = _status;
    }

    function getStatus() internal view returns (PetStatus) {
        PetStorage storage ps = petStorage();
        return ps.status;
    }

    function getHash() internal view returns (bytes32) {
        PetStorage storage ps = petStorage();
        return keccak256(abi.encode(ps.details));
    }

    function register() internal {
        require(canRegister(), "Registration Failed");
        PetStorage storage ps = petStorage();
        ps.registry.addPetDetails(getHash());
        require(ps.registry.isRegisteredPet(getHash()), "Failed to Update Registry");
        setStatus(PetStatus.Safe);
    }

    function lost() internal {
        require(canLose());
        PetStorage storage ps = petStorage();
        ps.registry.addLostPet(getHash());
        require(ps.registry.isLostPet(), "Failed to Update Registry");
        setStatus(PetStatus.Lost);
    }

    function found(uint _secret) internal {
        require(canFind());
        bytes32 _identifierHash = keccak256(abi.encodePacked(_secret));
        PetStorage storage ps = petStorage();
        require(_identifierHash == ps.identifier, "Invalid Secret");
        require(ps.registry.removeLostPet(), "Failed to Update Registry");
    } 

}


contract Pet {

    event NameChanged(string oldName, string newName);
    event StatusChanged(PetStatus indexed oldStatus, PetStatus indexed newStatus);
    event OwnerChanged(address indexed oldOwner, address indexed newOwner); //TODO Build support for this
    event KeeperChanged(address indexed oldKeeper, address indexed newKeeper);
    event RegistryChanged(address indexed oldRegistry, address indexed newRegistry);
    event ColorsChanged(PetColor indexed primaryColor, PetColor indexed secondaryColor, PetMarking indexed markings);

    modifier isOwner() {
        require(msg.sender == PetEngine.getOwner(), "Caller is not Pet Owner");
        _;
    }

    function owner() external view returns (address) {
        return PetEngine.getOwner();
    }

    function keeper() external view returns (address) {
        return PetEngine.getKeeper();
    }

    function name() external view returns (string memory) {
        return PetEngine.getName();
    }

    function petType() external view returns (PetType) {
        return PetEngine.getPetType();
    }

    function setPermDetails(PetType _petType, string memory _name, uint _dob) external isOwner {
        PetEngine.setPermDetails(_petType, _name, _dob);
    }

    function setColors(PetColor _primaryColor, PetColor _secondaryColor, PetMarking _markings) external isOwner {
        PetEngine.setColors(_primaryColor, _secondaryColor, _markings);
    }

    function setTemperment(PetTemperment _temperment, bool _respondsToName) external isOwner {
        PetEngine.setTemperment(_temperment, _respondsToName);
    }
    function setHome(uint8 _homeLatitude, uint8 _homeLongitude) external isOwner {
        PetEngine.setHome(_homeLatitude, _homeLongitude);
    }

    function init(bytes32 _identifier, address _owner, address _registry) external isOwner {
        PetEngine.init(_identifier, _owner, _registry);
    }

    function register() external isOwner {
        PetEngine.register();
    }

    function lost() external isOwner {
        PetEngine.lost();
    }

    function found(uint _secret) external {
        PetEngine.found(_secret);
    }



}




// contract Pet {

//     bytes32 public identifier; //Hash of Secret Number embedded on pet tag

//     address private owner;

//     address private keeper; //Same as owner when status == Safe, unset when lost, set to finder when found

//     PetStatus public status;

//     Registry private registry;

//     modifier isOwner() {
//         require(msg.sender == owner, "Caller is Not Owner");
//         _;
//     }

//     modifier isSafe(){
//         require(status == PetStatus.Safe, "Pet Not Safe");
//         _;
//     }

//     modifier isLost(){
//         require(status == PetStatus.Lost, "Pet Not Lost");
//         _;
//     }

//     modifier isUnregistered(){
//         require(status == PetStatus.Unregistered, "Pet Already Registered");
//         _;
//     }


//     constructor(bytes32 _identifier, address _owner, address _registry){
//         // identifier = keccak256(abi.encodePacked(_identifier));
//         identifier = _identifier;
//         owner = _owner;
//         registry = Registry(_registry);
//     }

//     function setStatus(PetStatus _newStatus) internal {
//         status = _newStatus;
//         //TODO Add an Event Here
//     }

//     function setSafe() internal {
//         setStatus(PetStatus.Safe);
//         keeper = owner;
//     }

//     function setLost() internal {
//         setStatus(PetStatus.Lost);
//         delete keeper; //Unset keeper as pet is presumed lost
//     }

//     function setFound(address _keeper) internal {
//         setStatus(PetStatus.Found);
//         keeper = _keeper;
//     }

//     function verify() public isOwner isUnregistered returns (bool){
//         bool didRegister = registry.isRegisteredPet();
//         if (!didRegister){
//             return false; //Not sure how this can happen but just in case
//         }
//         setSafe();
//     }

//     //TODO Add Reward Mechanism
//     function lost() public isOwner isSafe returns (bool){
//         bool didRegister = registry.addLostPet();
//         if (!didRegister){
//             return false;
//         }
//         setLost();
//         return true;
//     }

//     function found(uint _identifier) public isLost {
//         
//         if(_identifierHash != identifier){
//             revert ("Invalid Identifier!");
//         }
//         bool didRegister = registry.removeLostPet();
//         if (!didRegister){
//             revert("Failed to Update Registry!");
//         }
//         setFound(msg.sender); //Set keeper to caller with valid identifier, identifier is considered "burned"
//     }

// }