# OpenSUI

## Overview
pbt.move is a Move Smart Contract that is principally used to handle Physical Backed Tokens (PBTs). In broad terms, these tokens are issued by an artifact owner and are intrinsically linked/backed by the physical artifact's chip.

## Structs
**PhysicalArtifactToken**: This struct is a representation of a Physical Backed Token (PBT). It contains an assortment of fields delineating information about the token. Components of this struct embody the token's ID (token_id), details about the artifact (artifact_details), and the chip's public key (chip_pubkey). The PBT struct is primarily used to store and handle the details of each individual token issued.

**PhysicalArtifactArchive**: This is an Archive to keep a record of all artifact public keys. This is critical to ensure that each chip associated with a physical token is unique and to prevent counterfeits.

**PBT**: It defines an Outer to the Publisher object for the sender.

**AdminCap**: This essentially represents an administrative capability - a unique struct that gives permission for certain actions, facilitating the performance of specific operations like updating the PBT struct.

## Functions
**Minting new PBTs**: Issue new tokens with unique identifiers, details, and associated chip public keys.

**Transferring PBTs**: Transfer ownership of tokens from one account to another. This includes checks to 
validate ownership and ensure the transfer is appropriate.

**Updating Chips**: Allows for the updating of the public keys associated with each PBT. This ensures the linkage between a PBT and its physical counterpart remains updated and secure.

It's essential to note that these operations include checks to validate signatures and ensure all transactions maintain integrity and security.

## Conclusion
In conclusion, pbt.move is an eloquent example of a Move Smart Contract that effectively manages Physical Backed Tokens. The use of well-structured Structs and Functions allows for concise and secure operations regarding PBTs, making it a competent component for any application operating within the range of physical/digital token interactions.