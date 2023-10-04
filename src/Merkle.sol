// SPDX-License-Identifier: MIT
// Merkle Stash

pragma solidity ^0.8.0;

import {Owned} from "solmate/auth/Owned.sol";
import {SafeTransferLib} from "solmate/utils/SafeTransferLib.sol";
import {FixedPointMathLib} from "solmate/utils/FixedPointMathLib.sol";
import {MerkleProofLib} from "solmate/utils/MerkleProofLib.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract Merkle is Owned {
  using FixedPointMathLib for uint256;
  using SafeTransferLib for ERC20;

  struct claimParam {
      address token;
      uint256 index;
      uint256 amount;
      bytes32[] merkleProof;
  }

  // environment variables for updateable merkle
  mapping(address => bytes32) public merkleRoot;
  mapping(address => uint256) public update;

  // This is a packed array of booleans.
  mapping(address => mapping(uint256 => mapping(uint256 => uint256))) private claimedBitMap;

  function isClaimed(address token, uint256 index) public view returns (bool) {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    uint256 claimedWord = claimedBitMap[token][update[token]][claimedWordIndex];
    uint256 mask = (1 << claimedBitIndex);
    return claimedWord & mask == mask;
  }

  function _setClaimed(address token, uint256 index) private {
    uint256 claimedWordIndex = index / 256;
    uint256 claimedBitIndex = index % 256;
    claimedBitMap[token][update[token]][claimedWordIndex] = claimedBitMap[token][update[token]][claimedWordIndex] | (1 << claimedBitIndex);
  }

  function claim(address token, uint256 index, address account, uint256 amount, bytes32[] calldata merkleProof) public {
    require(merkleRoot[token] != 0, 'frozen');
    require(!isClaimed(token, index), 'Drop already claimed.');

    // Verify the merkle proof.
    bytes32 node = keccak256(abi.encodePacked(index, account, amount));
    require(MerkleProofLib.verify(merkleProof, merkleRoot[token], node), 'Invalid proof.');

    _setClaimed(token, index);
    ERC20(token).safeTransfer(account, amount);

    emit Claimed(token, index, amount, account, update[token]);
  }

  function claimMulti(address account, claimParam[] calldata claims) external {
    for(uint256 i=0;i<claims.length;++i) {
      claim(claims[i].token, claims[i].index, account, claims[i].amount, claims[i].merkleProof);
    }
  }

  // MULTI SIG FUNCTIONS //
  function freeze(address token) public onlyOwner {
    require(merkleRoot[token] != 0, "Already frozen");

    // Increment the update (simulates the clearing of the claimedBitMap)
    update[token] += 1;

    // Set the new merkle root
    merkleRoot[token] = 0;

    emit Frozen(token, update[token]);
  }

  function multiFreeze(address[] calldata tokens) public onlyOwner {
    uint256 length = tokens.length;
    uint256 i = 0;
    for(; i < length; ) {
      freeze(tokens[i]);
      unchecked {
        ++i;
      }
    }
  }

  function updateMerkleRoot(address token, bytes32 _merkleRoot) public onlyOwner {
    require(merkleRoot[token] == 0, "Not frozen");

    // Increment the update (simulates the clearing of the claimedBitMap)
    update[token] += 1;
    // Set the new merkle root
    merkleRoot[token] = _merkleRoot;

    emit MerkleRootUpdated(token, _merkleRoot, update[token]);
  }

  function multiUpdateMerkleRoot(address[] calldata tokens, bytes32[] calldata _merkleRoots) public onlyOwner {
    require(tokens.length == _merkleRoots.length, "!Length");

    uint256 length = tokens.length;
    uint256 i = 0;

    for(; i < length; ) {
      updateMerkleRoot(tokens[i], _merkleRoots[i]);
      unchecked {
        ++i;
      }
    }
  }

  // EVENTS //
  event Claimed(address indexed token, uint256 index, uint256 amount, address indexed account, uint256 indexed update);
  event MerkleRootUpdated(address indexed token, bytes32 indexed merkleRoot, uint256 indexed update);
  event Frozen(address indexed token, uint256 indexed update);
}