# ZK Wallet

Simple implementation of a smart contract wallet that you can claim ownership off, if you know a secret value that you commit to on deployment.

If you lose access to your EOA, you create a new one and claim ownership of this wallet by submitting a `claim()` transaction where you prove that you know a secret value `x`.


