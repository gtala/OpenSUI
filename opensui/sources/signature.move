// Copyright (c) Mysten Labs, Inc.
// SPDX-License-Identifier: Apache-2.0

module opensui::signature {
  // Sui imports. 
  use sui::clock::{Self, Clock};
  use std::hash::sha2_256;
  use sui::bls12381; 
  use sui::ecdsa_k1;

  // STD imports.
  use std::vector;

  // --- Errors ---

  /// Allowed TTL for signature: 1 minute in milliseconds.
  const SIGNATURE_TTL: u64 = 60_000;
  const DRAND_PERIOD: u64 = 30;

  /// Hash function we're using for secp256k1_verify. 
  const SHA256: u8 = 1;

  /// The genesis time of chain 8990e7a9aaed2ffed73dbd7092123d6f289930540d7651336225dc172e51b2ce.
  const GENESIS: u64 = 1595431050;

  /// The public key of chain 8990e7a9aaed2ffed73dbd7092123d6f289930540d7651336225dc172e51b2ce.
  const DRAND_PK: vector<u8> = 
    x"868f005eb8e6e4ca0a47c8a77ceaa5309a47978a7c71bc5cce96366b5d7a569937c529eeda66c7293784a9402801af31";
  
  /// Check if a signature is within the TTL based on given DRAND round.
  public fun is_within_ttl(round: u64, clock: &Clock): bool {
    // Get the current timestamp in ms. 
    let cur_timestamp = clock::timestamp_ms(clock);

    // Calculate the timestamp of the round. 
    // We use (round - 1) to convert to zero-based indexing.
    let round_timestamp_ms = (GENESIS + DRAND_PERIOD * (round - 1))*1000 ;
    
    // All future DRAND rounds are considered to be within the TTL.
    // This makes sure that future rounds are not rejected because of time 
    // synchronization issues.
    let response = if(cur_timestamp < round_timestamp_ms) {
      true
    } else {
      // Return whether the signature is within the TTL or not.
      (cur_timestamp - round_timestamp_ms) <= SIGNATURE_TTL
    };

    response
  }

  /// Check a drand output.
  public fun verify_drand_signature(
    sig: vector<u8>, // Signature to be verified.
    prev_sig: vector<u8>, // Previous signature.
    round: u64, // Round number of the signature.
  ): bool {
    // Convert round to a byte array in big-endian order.
    let round_bytes: vector<u8> = vector[0, 0, 0, 0, 0, 0, 0, 0];

    // A u64-bit integer can be represented by 8 bytes, thus the array indices are 0 to 7.
    // We start from 8 and go down to 1 to avoid arithmetic errors for negative numbers.
    let i = 8;

    // Extract each byte from the round integer.
    while (i > 0) {
        let curr_byte = round % 0x100;
        let curr_element = vector::borrow_mut(&mut round_bytes, i - 1);
        *curr_element = (curr_byte as u8);
        round = round >> 8;
        i = i - 1;
    };

    // Compute the SHA-256 hash of (prev_sig, round_bytes).
    // This creates a unique input for the hash function based on 
    // both the previous signature and the round number
    vector::append(&mut prev_sig, round_bytes);
    let digest = sha2_256(prev_sig);

    // Verify the signature based on the previous signature hash.
    bls12381::bls12381_min_pk_verify(&sig, &DRAND_PK, &digest)
  }

  /// Verify chip signature.
  public fun verify_signature(
    chip_sig: vector<u8>, 
    chip_pk: vector<u8>,
    drand_sig: vector<u8>,
    sender_address: vector<u8>,
  ): bool {
    // Recreate the message-to-sign that was used to generate the signature.
    let msg = vector::empty();
    
    // Message-to-sign is the concatenation of the sender address and 
    // the drand signature.
    vector::append(&mut msg, sender_address);
    vector::append(&mut msg, drand_sig);
    
    ecdsa_k1::secp256k1_verify(&chip_sig, &chip_pk, &msg, SHA256)
  }
}