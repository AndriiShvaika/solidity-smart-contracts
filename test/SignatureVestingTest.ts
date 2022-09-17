import { BigNumber } from "ethers";
import { ethers } from "hardhat";
import {
  SignatureVesting__factory,
  SignatureVesting,
  ERC20,
  ERC20__factory,
} from "../typechain";
import keccak256 from "keccak256";

describe("SignatureVesting", function () {
  let erc20: ERC20;
  let vesting: SignatureVesting;
  let defaultVestingBalance: BigNumber;

  beforeEach(async () => {
    const [owner] = await ethers.getSigners();
    console.log("owner", await owner.getAddress());
    erc20 = await new ERC20__factory(owner).deploy("SignatureToken", "STK");
    vesting = await new SignatureVesting__factory(owner).deploy(erc20.address);
    defaultVestingBalance = await erc20.balanceOf(await owner.getAddress());

    console.log(
      "start balance = ",
      ethers.utils.formatEther(defaultVestingBalance)
    );

    await erc20.transfer(vesting.address, defaultVestingBalance);
  });

  it("Should emit Vest event with correct data when vesting tokens", async function () {
    const claimer = ethers.provider.getSigner(2);
    const claimerAddress = await claimer.getAddress();
    console.log(claimerAddress);

    const message = ethers.utils.solidityPack(
      ["address", "uint256", "uint256", "address"],
      [claimerAddress, defaultVestingBalance.div(10), 1, vesting.address]
    );
    console.log(await ethers.provider.getSigner(0).getAddress());
    console.log("msg", message);

    const signature = await ethers.provider
      .getSigner(0)
      .signMessage(keccak256(message));
    console.log("sig", signature);
    const claimingTx = await vesting
      .connect(claimer)
      .claimTokens(defaultVestingBalance.div(10), 1, signature);
    claimingTx.wait();

    console.log("claimerTokenBal", await erc20.balanceOf(claimerAddress));
  });
});
