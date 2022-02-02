// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/utils/structs/EnumerableSet.sol";

library RegistryEngine {

    using EnumerableSet for EnumerableSet.AddressSet;

    


    struct RegistryStorage {
        address petSafe;
        mapping(address => bool) allPets;
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

    function isRegisteredPet(address _pet) public view returns (bool) {
        RegistryStorage storage rs = registryStorage();
        return rs.allPets[_pet];
    }

    function getLostPets() public view returns (address[] memory){
        RegistryStorage storage rs = registryStorage();
        return rs.lostPets.values();
    }

    function isLostPet(address _pet) public view returns (bool) {
        RegistryStorage storage rs = registryStorage();
        return rs.lostPets.contains(_pet);
    }

    function registerPet(address _pet) internal returns (bool) {
        RegistryStorage storage rs = registryStorage();
        if(rs.allPets[_pet]){
            return false;
        }
        rs.allPets[_pet] = true;
        return true;
    }

    function addLostPet(address _pet) internal returns (bool) {
        RegistryStorage storage rs = registryStorage();
        if (isRegisteredPet(msg.sender)){
            return rs.lostPets.add(_pet);
        } else {
            return false;
        }
    }

    function removeLostPet(address _pet) internal returns (bool) {
        RegistryStorage storage rs = registryStorage();     
        return rs.lostPets.remove(_pet);
    }



}


contract Registry {
   
   modifier isPetSafe() {
       require(msg.sender == RegistryEngine.getPetSafe(), "Caller is not PetSafe!");
       _;
   }

   modifier petIsRegistered() {
       require(RegistryEngine.isRegisteredPet(msg.sender), "Caller is not a Registered Pet!");
       _;
   }

   modifier petIsLost() {
       require(RegistryEngine.isLostPet(msg.sender), "Caller is not a Lost Pet!");
       _;
   }


   constructor() {
       RegistryEngine.setPetSafe(msg.sender);
   }

   function registerPet(address _newPet) public isPetSafe returns (bool){
       return RegistryEngine.registerPet(_newPet);
   }

   function addLostPet() public petIsRegistered returns (bool) {
       return RegistryEngine.addLostPet(msg.sender);
   }

   function removeLostPet() public petIsLost returns (bool) {
       return RegistryEngine.removeLostPet(msg.sender);
   }

   function lostPets() public view returns (address[] memory){
       return RegistryEngine.getLostPets();
   }

}
