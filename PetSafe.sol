// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Pet.sol";
import "./PetRegistry.sol";

enum Status {Closed, Open, OpenZima}



contract PetSafe {

    address constant Zima = 0x56ddd1f7543a15d8a0acDFcf447E197aA45F0EB7; //Obviously needs to be updated between networks
    Registry public registry;

    Status private status;

    modifier isZima() {
        require(msg.sender == Zima, "Caller is Not Zima!");
        _;
    }


    modifier canRegister() {
        if(status==Status.OpenZima){
            require(isZima());
            _;
        } else {
            require(status==Status.Open, "PetSafe is Closed");
            _;
        }
    }


    constructor(){
        registry = new Registry(); 
    }

    function registerPet(bytes32 _identifier) public canRegister returns (address){
        Pet newPet = new Pet(_identifier, msg.sender);
        bool didRegister = registry.registerPet(address(newPet));
        if (!didRegister){
            revert("Registration Failed!");
        }
        return address(newPet);
    }

    function setStatus(Status _newStatus) public isZima {
        status = _newStatus;
    }
}
