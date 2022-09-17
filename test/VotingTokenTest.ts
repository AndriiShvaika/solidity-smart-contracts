import { expect } from "chai";
import { ethers } from "hardhat";
import { VotingToken, VotingToken__factory } from "../typechain";

describe("Voting Token", function () {
  let erc20: VotingToken;

  beforeEach(async () => {
    let [signer] = await ethers.getSigners();
    erc20 = await new VotingToken__factory(signer).deploy(
      "PunkToken",
      "PTK",
      20000
    );
  });

  it("Should buy 5 tokens", async function () {
    await erc20.buy({
      value: ethers.utils.parseUnits("100000", "wei"),
    });

    const address = await ethers.provider.getSigner(0).getAddress();
    const balance = await erc20.balanceOf(address);

    expect(balance).to.be.equal("5");
  });

  it("Should start voting and vote for price 4000", async function () {
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    const newTimestamp = timestampBefore + 120;

    await erc20.startVoting(newTimestamp);
    await erc20.vote(4000);

    const isVotingEnded = await erc20.votingEnded();
    const tokenPrice = await erc20._currentPriceInWei();

    expect(isVotingEnded).to.be.equal(false);
    expect(tokenPrice).to.be.equal(4000);
  });

  it("Second account should buy 10 tokens, start voting and vote for price 1500, then third account should buy 2 tokens and vote for price 2000, but contract won't accept it because the account has low amount of tokens", async function () {
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    const newTimestamp = timestampBefore + 120;

    await erc20.connect(ethers.provider.getSigner(1)).buy({
      value: ethers.utils.parseUnits("200000", "wei"),
    });

    await erc20.connect(ethers.provider.getSigner(1)).startVoting(newTimestamp);
    await erc20.connect(ethers.provider.getSigner(1)).vote(1500);

    await erc20.connect(ethers.provider.getSigner(2)).buy({
      value: ethers.utils.parseUnits("3000", "wei"),
    });

    const isVotingEnded = await erc20.votingEnded();
    const tokenPrice = await erc20._currentPriceInWei();

    expect(isVotingEnded).to.be.equal(false);
    expect(tokenPrice).to.be.equal(1500);
  });
});
