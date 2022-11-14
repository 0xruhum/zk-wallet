pragma circom 2.1.0;

include "../../lib/circomlib/circuits/poseidon.circom";

// Circuit that allows you to prove that you know secret value X.
template Claim () {
    // public
    signal input hashedPreimage;
    // simply the uint representation of an address
    // uint256(uint160(addr))
    signal input address;
    // we need a nullifier so nobody can frontrun the tx
    // nullifier = Poseidon(preimage, address)
    signal input nullifier;
    // private
    signal input preimage;
    
    component hash = Poseidon(1);
    hash.inputs[0] <== preimage;
    hash.out === hashedPreimage;
    component hash2 = Poseidon(2);
    hash2.inputs[0] <== preimage;
    hash2.inputs[1] <== address;

    nullifier === hash2.out;
}

component main { public [ hashedPreimage, address, nullifier ] } = Claim();

