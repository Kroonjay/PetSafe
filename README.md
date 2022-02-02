# A Pet Registry on the Blockchain
## Concepts
Two Variants, a tag and a microchip
Tag Variant
- A Secret Number is etched onto a pet tag
- This number is hashed and posted to the Pet contract
  - This means each tag must be "burnt" after being lost and found
- Pets have a lost function that updates a status enum mapping in Registry
- Pets also have a Found function that updates the same status
  - Function can only be call
- Rewards for Finding pets
Pet Statuses
- Safe
- Lost
- UserFound
- Deceased :(
- VetFound
- PoundFound
 

## Contracts

### Pet (Abstract)

- Identification Number
- Breed
  - Enum
- Primary Color
- Secondary Color
- Markings?
  - Spots, Striped, Marble, etc.
- Date of Birth
  - timestamp
- Current Owner
  - Address

### Pet Keeper (Abstract)
- owner
  - Address
    - A token given to the owner when signing up for the service
- Primary Contact
  - Struct of Owner first name, phone.  Signed by Registry before posted to blockchain
- Secondary Contact
  - Struct of Owner first name, phone.  Signed by Registry before posted to blockchain
- Home Address
  - Struct of Owner home address, optional.  Signed by Registry before posted to blockchain

### Pet Registry
- petSecrets
  - bytes32 -> address mapping of id hashes to pet addresses
- foundRewards
  - address -> uint EnumerableMap of rewards posted for lost pets
- 