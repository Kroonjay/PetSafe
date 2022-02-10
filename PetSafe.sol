// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Pet.sol";
import "./PetRegistry.sol";

enum Status {Closed, Open, OpenZima}


//TODO ADD function to generate a hash
//TODO Re-Write this to use Diamond pattern
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
            require(msg.sender == Zima, "PetSafe is Closed");
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
        Pet newPet = new Pet();
        newPet.init(_identifier, msg.sender, address(registry));
        bool didRegister = registry.addNewPet(address(newPet), msg.sender);
        if (!didRegister){
            revert("Registration Failed!");
        }
        return address(newPet);
    }

    function setStatus(Status _newStatus) internal isZima {
        status = _newStatus;
    }

    function open() public isZima {
        setStatus(Status.Open);
    }

    function getIdentifier(uint _secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_secret));
    }
}

