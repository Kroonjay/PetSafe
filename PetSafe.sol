// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;
import "./Pet.sol";
import "./PetRegistry.sol";

enum Status {Closed, Open, OpenZima}


//TODO ADD function to generate a hash
//TODO Re-Write this to use Diamond pattern
contract PetSafe {

    event StatusChanged(uint indexed _oldStatus, uint indexed _newStatus);
    event FeeChanged(uint indexed _oldFee, uint indexed _newFee);
    event Withdrawal(uint indexed _balance);

    address payable constant Zima = payable(0x56ddd1f7543a15d8a0acDFcf447E197aA45F0EB7);
    Registry public registry;
    uint private balance;
    Status public status;
    uint256 public registrationFee; //Cost (in wei) to register a new Pet

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

    function registerPet(bytes32 _identifier) payable public canRegister returns (address){
        require (msg.value == registrationFee, "Invalid Deposit Amount!");       
        balance += msg.value;
        Pet newPet = new Pet();
        newPet.init(_identifier, msg.sender, address(registry));
        bool didRegister = registry.addNewPet(address(newPet), msg.sender);
        if (!didRegister){
            revert("Registration Failed!");
        }
        return address(newPet);
    }

    function getBalance() public view isZima returns(uint){
        return balance;
    }

    function setStatus(Status _newStatus) internal isZima {
        emit StatusChanged(uint(status), uint(_newStatus));
        status = _newStatus;
    }

    function setRegistrationFee(uint256 _newFee) external isZima {
        emit FeeChanged(registrationFee, _newFee);
        registrationFee = _newFee;
    }

    function open() public isZima {
        setStatus(Status.Open);
    }

    function getIdentifier(uint _secret) public pure returns (bytes32) {
        return keccak256(abi.encodePacked(_secret));
    }

    function withdraw() public isZima {
        emit Withdrawal(balance);
        Zima.transfer(balance);

    }
}

