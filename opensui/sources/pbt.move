/// Physical Backed Token (PBT) module.
/// PBTs are minted by an artifact owner and are backed by the physical artifact's chip.
/// Handles minting, update and transfer of PBTs.
module opensui::pbt {
  // Sui imports. 
  use sui::tx_context::{TxContext, sender};
  use sui::object::{Self, UID};
  use sui::transfer::{Self};
  use sui::clock::{Clock};
  use sui::package::{Self};
  use sui::dynamic_field as df;
  use sui::tx_context;
  use sui::address;
  use sui::display;

  // STD imports.
  use std::string::{utf8, String};
  use std::vector;

  // Package dependencies.
  use opensui::signature::{Self as qsig};

  // Error codes. 
  const EInvalidSignature: u64 = 1;
  const ESignatureExpired: u64 = 2;
  const EArtifactDoesNotExist: u64 = 3;
  const EArtifactAlreadyMinted: u64 = 4;
  const ETransferNotAllowed: u64 = 5;
  
  // Artifact helper consts. 
  const MINTED: u8 = 1;
  const NOT_MINTED: u8 = 0;

  // Physical Backed Token (PBT) struct.
  struct PhysicalArtifactToken has key {
    id: UID,
    chip_pk: vector<u8>, // chip public key.
    name: String, // name of the artifact.
    description: String, // description of the artifact.
    url: String, // image url of the artifact.
    animation_url: String, // video url of the artifact.
    external_url: String, // external url of the artifact.
    attributes_keys: vector<String>, // attributes_keys of the artifact.
    attributes_values: vector<String>, // attributes values of the artifact.

  }

  struct PhysicalArtifactTokenAttribute has store {
    trait_type: String,
    value: String,
  }

  // PBT archive that keeps track of all artifact public keys.
  // Dynamic fields will be added here in a format of token_id: MINTED | NOT_MINTED.
  struct PhysicalArtifactArchive has key, store {
    id: UID
  }

  /// Define an OTW to the `Publisher` object for the sender.
  struct PBT has drop {}

  /// Define an admin capability for giving permission for certain actions.
  struct AdminCap has key, store {
    id: UID,
  }

  fun init(otw: PBT, ctx: &mut TxContext) {
    // Claim the `Publisher` for the package.
    let publisher = package::claim(otw, ctx);

    // Set up default Display propery. 
     let keys = vector[
      utf8(b"chip_pk"),
      utf8(b"name"),
      utf8(b"description"),
      utf8(b"url"),
      utf8(b"animation_url"),
      utf8(b"external_url"),
      utf8(b"attributes_keys"),
      utf8(b"attributes_values"),
    ];

    // TODO: Replace with actual default values.
    let values = vector[
      utf8(b"{chip_pk}"),
      utf8(b"{name}"),
      utf8(b"{description}"),
      utf8(b"{url}"),
      utf8(b"{animation_url}"),
      utf8(b"{external_url}"),
      utf8(b"{attributes_keys}"),
      utf8(b"{attributes_values}"),

    ];

    let display = display::new_with_fields<PhysicalArtifactToken>(
      &publisher, keys, values, ctx
    );
    
    // Commit first version of `Display` to apply changes.
    display::update_version(&mut display);

     // Create a new `AdminCap` object.
    let admin_cap = AdminCap {
      id: object::new(ctx)
    };
    // Create a new PBT archive.
    let archive = PhysicalArtifactArchive {
      id: object::new(ctx),
    };

    transfer::share_object(archive);
    transfer::public_transfer(publisher, sender(ctx));
    transfer::public_transfer(display, sender(ctx));
    transfer::public_transfer(admin_cap, sender(ctx));
  }

  /// Admin can add to the PhysicalArtifact archive a new artifact's public key.
  public fun admin_add_to_archive(
    _cap: &AdminCap, archive: &mut PhysicalArtifactArchive, chip_pk: vector<u8>
  ) {
    add_to_archive_(archive, chip_pk);
  }

  /// If caller has valid signature, they mint a new PBT.
  public fun mint(
    chip_sig: vector<u8>,
    chip_pk: vector<u8>,
    drand_sig: vector<u8>, 
    prev_drand_sig: vector<u8>,
    drand_round: u64,
    archive: &mut PhysicalArtifactArchive,
    clock: &Clock, 
    ctx: &mut TxContext
  ) {
    // Make sure the chip exists in PhysicalArtifactArchive and has not been minted yet.
    // Aborts with `EFieldDoesNotExist` if the object does not have a field with that name.
    // Aborts with `EFieldTypeMismatch` if the field exists, but the value does not have the specified type.
    assert!(*df::borrow<vector<u8>, u8>(&archive.id, chip_pk) == NOT_MINTED, EArtifactAlreadyMinted);

    // Verify signature is within TTL.
    assert!(qsig::is_within_ttl(drand_round, clock), ESignatureExpired);

    // Verify DRAND signature validity. 
    assert!(qsig::verify_drand_signature(drand_sig, prev_drand_sig, drand_round), EInvalidSignature);

    // Verify chip signature validity.
    let address_bytes = address::to_bytes(sender(ctx));
    assert!(qsig::verify_signature(chip_sig, chip_pk, drand_sig, address_bytes), EInvalidSignature);

    // Build the attributes_keys vector.
    let attributes_keys = vector::empty<String>();
            // Build the attributes_keys vector.
    let attributes_values = vector::empty<String>();

    vector::push_back(&mut attributes_keys,  utf8(b"Brass Weight (Grms)"));
    vector::push_back(&mut attributes_values, utf8(b"300"));

    vector::push_back(&mut attributes_keys,  utf8(b"Precious Stone Weight (Grms)"));
    vector::push_back(&mut attributes_values, utf8(b"9"));

    vector::push_back(&mut attributes_keys,  utf8(b"Copper Weight (Grms)"));
    vector::push_back(&mut attributes_values, utf8(b"0.5"));

    vector::push_back(&mut attributes_keys,  utf8(b"Copper Weight (Grms)"));
    vector::push_back(&mut attributes_values, utf8(b"0.5"));

    vector::push_back(&mut attributes_keys,  utf8(b"Silver Weight (Grms)"));
    vector::push_back(&mut attributes_values, utf8(b"0.25"));

    vector::push_back(&mut attributes_keys,  utf8(b"Gold Weight (Grms)"));
    vector::push_back(&mut attributes_values, utf8(b"1"));

    vector::push_back(&mut attributes_keys,  utf8(b"Cultural Keeper"));
    vector::push_back(&mut attributes_values, utf8(b"Jro Mangku I Wayan Sudiarta"));

    vector::push_back(&mut attributes_keys,  utf8(b"Location"));
    vector::push_back(&mut attributes_values, utf8(b"Klungkung, Bali, Indonesia"));

    // If signature is valid, mint a new PBT.
    let pbt = PhysicalArtifactToken {
      id: object::new(ctx),
      chip_pk,
     name: utf8(b"OpenSui"),
      description: utf8(b"Open Sui PBT Implementation and Metadata Renderer"),
      url: utf8(b"ipfs://QmRyNLcqjyUikS13P5GSJgFJkhoSaXH4u4j6EXAJFsXNEt/bell.jpg"),
      animation_url: utf8(b"https://ipfs.io/ipfs/QmYh2c8nHShD46zk5RPVA71oHwxRUC8x9HWkZZ4pyZEMQR/Bell_4K_LOOP_Clockwise%20%281%29.mp4"),
      external_url: utf8(b""),
      attributes_keys,
      attributes_values
    };

    // Update current artifact status to MINTED (1) in the archive.
    update_archive_(archive, chip_pk, MINTED);

    // PhysicalArtifactToken does not have store, so we need to transfer it to the sender.
    transfer::transfer(pbt, tx_context::sender(ctx));
  }

  /// If caller has valid signature, they transfer ownership of PBT to receiver.
  public fun transfer_ownership_to_address(
    chip_sig: vector<u8>, 
    drand_sig: vector<u8>, 
    prev_drand_sig: vector<u8>,
    drand_round: u64,
    pbt: PhysicalArtifactToken,
    receiver: address,
    clock: &Clock, 
    ctx: &mut TxContext
  ) {
    // Don't allow transfer to self.
    assert!(sender(ctx) != receiver, ETransferNotAllowed);

    // Verify signature is within TTL.
    assert!(qsig::is_within_ttl(drand_round, clock), ESignatureExpired);

    // Verify DRAND signature validity. 
    assert!(qsig::verify_drand_signature(drand_sig, prev_drand_sig, drand_round), EInvalidSignature);

    // Verify chip signature validity.
    let address_bytes = address::to_bytes(sender(ctx));
    assert!(qsig::verify_signature(chip_sig, pbt.chip_pk, drand_sig, address_bytes), EInvalidSignature);

    // If signature is valid, transfer ownership of PBT to receiver.
    transfer::transfer(pbt, receiver);
  }

  /// Update the chip_pk field of their PhysicalArtifactToken.
  /// A valid recent signature of the new chip_pk is required.
  /// Both the new and old chip_pk must exist in the public artifacts archive.
  /// After updating PhysicalArtifactToken with a new chip_pk, the old chip_pk is removed from the archive.
  public fun update_chip_pk(
    chip_sig: vector<u8>, 
    new_chip_pk: vector<u8>,
    drand_sig: vector<u8>, 
    prev_drand_sig: vector<u8>,
    drand_round: u64,
    pbt: &mut PhysicalArtifactToken,
    archive: &mut PhysicalArtifactArchive,
    clock: &Clock, 
    ctx: &mut TxContext
  ) {
    // Make sure the new chip exists in the public artifacts archive.
    assert!(df::exists_(&archive.id, new_chip_pk), EArtifactDoesNotExist);

    // Verify signature is within TTL.
    assert!(qsig::is_within_ttl(drand_round, clock), ESignatureExpired);

    // Verify DRAND signature validity. 
    assert!(qsig::verify_drand_signature(drand_sig, prev_drand_sig, drand_round), EInvalidSignature);

    // Verify chip signature validity.
    let address_bytes = address::to_bytes(sender(ctx));
    assert!(qsig::verify_signature(chip_sig, new_chip_pk, drand_sig, address_bytes), EInvalidSignature);

    // Remove and update aborts with `EFieldDoesNotExist` if the object does not have a field with that name.

    // If signature is valid, remove the old chip_pk from the archive.
    remove_from_archive_(archive, pbt.chip_pk);
    
    // Update the chip_pk field of the PBT.
    pbt.chip_pk = new_chip_pk;
   
    // Set the status of the new_chip_pk in Archive to MINTED.
    update_archive_(archive, new_chip_pk, MINTED);
  }

  // --- Private functions ---

  /// Update an artifact's status in PhysicalArtifact archive.
  /// Aborts with `EFieldDoesNotExist` if the object does not have a field with that name.
  /// Aborts with `EFieldTypeMismatch` if the field exists, but the value does not have the specified type.
  fun update_archive_(
    archive: &mut PhysicalArtifactArchive, chip_pk: vector<u8>, status: u8
  ) {
    *df::borrow_mut<vector<u8>, u8>(&mut archive.id, chip_pk) = status;
  }

  /// Add a chip_pk to PhysicalArtifact archive.
  /// Aborts with `EFieldAlreadyExists` if the object already has that field with that name.
  fun add_to_archive_(
    archive: &mut PhysicalArtifactArchive, chip_pk: vector<u8>
  ) {
    df::add(&mut archive.id, chip_pk, NOT_MINTED);
  }

  /// Remove a chip_pk from PhysicalArtifact archive.
  /// Aborts with `EFieldDoesNotExist` if the object does not have a field with that name.
  /// Aborts with `EFieldTypeMismatch` if the field exists, but the value does not have the specified type.
  fun remove_from_archive_(
    archive: &mut PhysicalArtifactArchive, chip_pk: vector<u8>
  ) {
    df::remove<vector<u8>, u8>(&mut archive.id, chip_pk);
  }

  #[test_only]
  public fun init_for_test(ctx: &mut TxContext){
    init( PBT {}, ctx);
  }

  #[test_only]
  public fun mint_for_test(chip_pk: vector<u8>, receiver: address, ctx: &mut TxContext){

    let pbt = PhysicalArtifactToken{
      id: object::new(ctx),
      chip_pk,
      name: utf8(b"OpenSui"),
      description: utf8(b"Open Sui PBT Implementation and Metadata Renderer"),
      url: utf8(b"ipfs://QmRyNLcqjyUikS13P5GSJgFJkhoSaXH4u4j6EXAJFsXNEt/bell.jpg"),
      animation_url: utf8(b"https://ipfs.io/ipfs/QmYh2c8nHShD46zk5RPVA71oHwxRUC8x9HWkZZ4pyZEMQR/Bell_4K_LOOP_Clockwise%20%281%29.mp4"),
      external_url: utf8(b"https://opensui.xyz/"),
      attributes_keys: vector::empty<String>(),
      attributes_values: vector::empty<String>()
    };

    transfer::transfer(pbt, receiver);

  }
}
