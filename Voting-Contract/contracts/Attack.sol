//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "./VotingToken.sol";

contract TokenAttacker {
    VotingToken private _contract;

    function attack(VotingToken contract_) external payable {
        _contract = contract_;

        require(_contract.votingEnded() == false, "Voting not started");
        require(_contract.balanceOf(msg.sender) != 0, "Balance cannot be 0");

        try _contract.vote(10000000000000000000000) {} catch {
            console.log("First sell error");
        }
        console.log(_contract._currentPriceInWei());
    }
}
