// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "./EnumerableSet.sol";

library RegistryEngine {

    using EnumerableSet for EnumerableSet.AddressSet;

    event PetCreated(uint PetCount, address indexed PetAddress, address indexed OwnerAddress);
    event PetRegistered(address indexed PetAddress, bytes32 indexed PetDetails);
    event PetLost(address indexed PetAddress, bytes32 indexed PetDetails);
    event PetFound(address indexed PetAddress, address indexed KeeperAddress);



    struct RegistryStorage {
        address petSafe;
        uint petCount;
        mapping(address => bool) allPets;
        mapping(bytes32 => address) petDetails; //Mapping of pet hashes that can be used to identify a pet based on characteristics, set during registration
        EnumerableSet.AddressSet lostPets;
    }

    address constant Zima = 0x56ddd1f7543a15d8a0acDFcf447E197aA45F0EB7; //Obviously needs to be updated between networks

    function registryStorage() internal pure returns (RegistryStorage storage rs) {
        bytes32 position = keccak256("diamond.standard.petsafe.registry.storage");
        assembly { rs.slot := position }
    }

    function getPetSafe() public view returns (address) {
        RegistryStorage storage rs = registryStorage();
        return rs.petSafe;
    }


    function setPetSafe(address _petSafe) internal {
        RegistryStorage storage rs = registryStorage();
        rs.petSafe = _petSafe;
    }

    function isPet(address _pet) public view returns (bool) {
        RegistryStorage storage rs = registryStorage();
        return rs.allPets[_pet];
    }

    function isValidDetails(bytes32 _details, address _pet) internal view returns (bool){
        RegistryStorage storage rs = registryStorage();
        if (rs.petDetails[_details] != address(0)){
            if(rs.petDetails[_details] == _pet) {
                return true;
            }
        }
        return false;
    }

    
    function isRegisteredPet(bytes32 _details, address _pet) public view returns (bool) {
        if(isPet(_pet)){
            if(isValidDetails(_details, _pet)){
                return true;
            }
        }
        return false;
    }

    function getPetCount() public view returns (uint){
        RegistryStorage storage rs = registryStorage();
        return rs.petCount;
    }

    function getLostPets() public view returns (address[] memory){
        RegistryStorage storage rs = registryStorage();
        return rs.lostPets.values();
    }

    function isLostPet(address _pet) public view returns (bool) {
        RegistryStorage storage rs = registryStorage();
        return rs.lostPets.contains(_pet);
    }

    function addNewPet(address _pet, address _owner) internal returns (bool) {
        RegistryStorage storage rs = registryStorage();
        if(rs.allPets[_pet]){
            return false;
        }
        rs.allPets[_pet] = true;
        rs.petCount++;
        emit PetCreated(rs.petCount, _pet, _owner);
        return true;
    }

    function addPetDetails(address _pet, bytes32 _details) internal {
        RegistryStorage storage rs = registryStorage();
        rs.petDetails[_details] = _pet;
        emit PetRegistered(_pet, _details);
    }

    function addLostPet(address _pet, bytes32 _petDetails) internal returns (bool) {
        RegistryStorage storage rs = registryStorage();
        if (isPet(_pet)){
            emit PetLost(_pet, _petDetails);
            return rs.lostPets.add(_pet);
        } else {
            return false;
        }
    }

    function removeLostPet(address _pet, address _keeper) internal returns (bool) {
        RegistryStorage storage rs = registryStorage();     
        emit PetFound(_pet, _keeper);
        return rs.lostPets.remove(_pet);
    }



}


contract Registry {

    event PetCreated(uint PetCount, address indexed PetAddress, address indexed OwnerAddress);
    event PetRegistered(address indexed PetAddress, uint indexed PetType, string indexed PetName);
    event PetLost(address indexed PetAddress, bytes32 indexed PetDetails);
    event PetFound(address indexed PetAddress, address indexed KeeperAddress);

   
   modifier isPetSafe() {
       require(msg.sender == RegistryEngine.getPetSafe(), "Caller is not PetSafe!");
       _;
   }

    modifier petIsValid() {
        require(RegistryEngine.isPet(msg.sender), "Caller is Not a Valid Pet!");
        _;
    }

   modifier petIsRegistered(bytes32 _details) {
       require(RegistryEngine.isRegisteredPet(_details, msg.sender), "Caller is not a Registered Pet!");
       _;
   }

   modifier petIsLost() {
       require(RegistryEngine.isLostPet(msg.sender), "Caller is not a Lost Pet!");
       _;
   }


   constructor() {
       RegistryEngine.setPetSafe(msg.sender);
   }

   function addNewPet(address _newPet, address _petOwner) public isPetSafe returns (bool){
       return RegistryEngine.addNewPet(_newPet, _petOwner);
   }

   function addPetDetails(bytes32 _details) public petIsValid {
       RegistryEngine.addPetDetails(msg.sender, _details);
   }

   function isPet() public view returns (bool){
       return RegistryEngine.isPet(msg.sender);
   }

   function petCount() public view returns (uint){
       return RegistryEngine.getPetCount();
   }

   function isRegisteredPet(bytes32 _details) public view returns (bool){
       return RegistryEngine.isRegisteredPet(_details, msg.sender);
   }

   function isLostPet() public view returns (bool){
       return RegistryEngine.isLostPet(msg.sender);
   }

   function addLostPet(bytes32 _details) public petIsRegistered(_details) returns (bool) {
       return RegistryEngine.addLostPet(msg.sender, _details);
   }

   function removeLostPet(address _keeper) public petIsLost returns (bool) {
       return RegistryEngine.removeLostPet(msg.sender, _keeper);
   }

   function lostPets() public view returns (address[] memory){
       return RegistryEngine.getLostPets();
   }

}
