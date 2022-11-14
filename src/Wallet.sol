pragma solidity 0.8.14;

import "./claim.sol";

contract Wallet is Verifier {
    address public owner;
    bytes32 public immutable hashedPreimage;

    constructor(address _owner, bytes32 _hashedPreimage) {
        owner = _owner;
        hashedPreimage = _hashedPreimage;
    }

    function claim(Verifier.Proof memory proof, uint256 nullifier) external {
        uint256[] memory inputs = new uint[](3);
        inputs[0] = uint256(hashedPreimage);
        inputs[1] = uint256(uint160(msg.sender));
        inputs[2] = nullifier;
        require(verify(inputs, proof) == 1, "invalid proof");

        owner = msg.sender;
    }

    function multicall(address[] calldata targets, bytes[] calldata data, uint256[] calldata values) external payable {
        require(msg.sender == owner, "Unauthorized");
        for (uint256 i; i < targets.length;) {
            (bool success, bytes memory result) = targets[i].call{value: values[i]}(data[i]);
            if (!success) {
                // Next 5 lines from https://ethereum.stackexchange.com/a/83577
                if (result.length < 68) {
                    revert();
                }
                assembly {
                    result := add(result, 0x04)
                }
                revert(abi.decode(result, (string)));
            }
            unchecked {
                ++i;
            }
        }
    }
}
