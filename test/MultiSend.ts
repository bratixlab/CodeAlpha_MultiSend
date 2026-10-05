import { expect } from "chai";
import { network } from "hardhat";

const { ethers } = await network.create();

describe("MultiSend", function () {
  it("should send an equal amount of ether to each recipient", async function () {
    const multiSend = await ethers.deployContract("MultiSend");
    const [, addr1, addr2, addr3] = await ethers.getSigners();

    const recipients = [addr1.address, addr2.address, addr3.address];
    const sendValue = ethers.parseEther("3");

    const balancesBefore = await Promise.all(
      recipients.map((r) => ethers.provider.getBalance(r)),
    );

    await multiSend.multiSendEqual(recipients, { value: sendValue });

    const balancesAfter = await Promise.all(
      recipients.map((r) => ethers.provider.getBalance(r)),
    );

    for (let i = 0; i < recipients.length; i++) {
      expect(balancesAfter[i] - balancesBefore[i]).to.equal(
        ethers.parseEther("1"),
      );
    }
  });

  it("should emit a Sent event for each recipient and MultiSendCompleted at the end", async function () {
    const multiSend = await ethers.deployContract("MultiSend");
    const [, addr1, addr2] = await ethers.getSigners();

    const recipients = [addr1.address, addr2.address];
    const sendValue = ethers.parseEther("2");

    await expect(multiSend.multiSendEqual(recipients, { value: sendValue }))
      .to.emit(multiSend, "Sent")
      .withArgs(addr1.address, ethers.parseEther("1"))
      .to.emit(multiSend, "Sent")
      .withArgs(addr2.address, ethers.parseEther("1"))
      .to.emit(multiSend, "MultiSendCompleted")
      .withArgs(2n, ethers.parseEther("2"));
  });

  it("should revert when given an empty recipients array", async function () {
    const multiSend = await ethers.deployContract("MultiSend");

    await expect(
      multiSend.multiSendEqual([], { value: ethers.parseEther("1") }),
    ).to.be.revertedWithCustomError(multiSend, "NoRecipients");
  });

  it("should revert when the per-recipient amount rounds down to zero", async function () {
    const multiSend = await ethers.deployContract("MultiSend");
    const signers = await ethers.getSigners();
    const recipients = signers.slice(1, 6).map((s) => s.address); // 5 recipients

    await expect(
      multiSend.multiSendEqual(recipients, { value: 1n }), // 1 wei / 5 = 0 each
    ).to.be.revertedWithCustomError(multiSend, "InsufficientValue");
  });

  it("should refund leftover dust to the sender on uneven division", async function () {
    const multiSend = await ethers.deployContract("MultiSend");
    const [sender, addr1, addr2, addr3] = await ethers.getSigners();
    const recipients = [addr1.address, addr2.address, addr3.address];

    const senderBalanceBefore = await ethers.provider.getBalance(sender.address);

    const tx = await multiSend
      .connect(sender)
      .multiSendEqual(recipients, { value: 10n }); // 10 / 3 = 3 each, 1 wei dust
    const receipt = await tx.wait();
    const gasCost = receipt!.gasUsed * receipt!.gasPrice;

    const senderBalanceAfter = await ethers.provider.getBalance(sender.address);

    // sender paid 9 wei to recipients + gas, and got 1 wei dust refunded
    expect(senderBalanceBefore - senderBalanceAfter).to.equal(9n + gasCost);
  });
});