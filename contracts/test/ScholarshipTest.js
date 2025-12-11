const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Scholarship", function () {
  async function deployScholarshipFixture() {
    const [deployer, committee1, committee2, applicant, donor, extraCommittee] =
      await ethers.getSigners();

    const Scholarship = await ethers.getContractFactory("Scholarship");

    // Deploy with 0.01 ETH seed as required by the constructor
    const committeeArray = [committee1.address, committee2.address];
    const seed = ethers.parseEther("0.01");

    const scholarship = await Scholarship.connect(deployer).deploy(committeeArray, {
      value: seed,
    });

    await scholarship.waitForDeployment();

    return {
      scholarship,
      deployer,
      committee1,
      committee2,
      applicant,
      donor,
      extraCommittee,
    };
  }

  it("deploys with correct initial state", async function () {
    const { scholarship, committee1, committee2 } = await deployScholarshipFixture();

    expect(await scholarship.isCommittee(committee1.address)).to.equal(true);
    expect(await scholarship.isCommittee(committee2.address)).to.equal(true);
    expect(await scholarship.committeeCount()).to.equal(2n);

    const roundInfo = await scholarship.getRoundInfo();
    // roundInfo: (round, phase, appsCount, startTime, hasWinner, winner)
    expect(roundInfo.round).to.equal(1n);
    expect(roundInfo.currentPhase).to.equal(0n); // Applications
    expect(roundInfo.appsCount).to.equal(0n);
    expect(roundInfo.hasWinner).to.equal(false);
    expect(roundInfo.winner).to.equal(ethers.ZeroAddress);
  });

  it("allows non-committee to apply and prevents double apply or committee applying", async function () {
    const { scholarship, committee1, applicant } = await deployScholarshipFixture();

    // committee cannot apply
    await expect(
      scholarship.connect(committee1).applyfor("ipfs://committee-try")
    ).to.be.revertedWith("Committee members cannot apply");

    // first application succeeds
    await expect(
      scholarship.connect(applicant).applyfor("ipfs://first-app")
    )
      .to.emit(scholarship, "ApplicationSubmitted")
      .withArgs(1n, 1n, applicant.address, "ipfs://first-app");

    const roundInfoAfter = await scholarship.getRoundInfo();
    expect(roundInfoAfter.appsCount).to.equal(1n);

    // same address cannot apply twice in same round
    await expect(
      scholarship.connect(applicant).applyfor("ipfs://second-app")
    ).to.be.revertedWith("You have already applied this round");
  });

  it("enforces donation > 0 and updates balance", async function () {
    const { scholarship, donor } = await deployScholarshipFixture();

      // 0 donation reverts
    await expect(
      scholarship.connect(donor).donate({ value: 0 })
    ).to.be.revertedWith("Donation must be > 0");

    const donateAmount = ethers.parseEther("1");
    await expect(
      scholarship.connect(donor).donate({ value: donateAmount })
    )
      .to.emit(scholarship, "Donated")
      .withArgs(donor.address, donateAmount);

    const contractBalance = await ethers.provider.getBalance(
      await scholarship.getAddress()
    );
    // initial seed 0.01 + 1 ETH donated
    expect(contractBalance).to.equal(ethers.parseEther("1.01"));
  });

  it("full flow: apply → donate → startVoting → vote → selectWinner", async function () {
    const {
      scholarship,
      committee1,
      committee2,
      applicant,
      donor,
    } = await deployScholarshipFixture();

    // 1. application
    await scholarship.connect(applicant).applyfor("ipfs://student-app");

    let roundInfo = await scholarship.getRoundInfo();
    expect(roundInfo.appsCount).to.equal(1n);
    expect(roundInfo.currentPhase).to.equal(0n); // Applications

    // 2. donate some extra ETH
    const donateAmount = ethers.parseEther("1");
    await scholarship.connect(donor).donate({ value: donateAmount });

    // 3. move to voting phase (we disabled the time check for demo in startVoting)
    await scholarship.connect(committee1).startVoting();

    roundInfo = await scholarship.getRoundInfo();
    expect(roundInfo.currentPhase).to.equal(1n); // Voting

    // 4. committee votes for appId = 1
    await scholarship.connect(committee1).vote(1);
    await scholarship.connect(committee2).vote(1);

    const app = await scholarship.getApplication(1, 1);
    expect(app.voteCount).to.equal(2n);

    // 5. time travel for selectWinner if you still have the time-based require in selectWinner
    //    (if you commented that out for demo, you can skip this section)
    const applicationDuration = await scholarship.applicationDuration();
    const votingDuration = await scholarship.votingDuration();
    const totalWait = applicationDuration + votingDuration + 1n;

    await ethers.provider.send("evm_increaseTime", [Number(totalWait)]);
    await ethers.provider.send("evm_mine", []);

    // 6. select winner
    const contractAddr = await scholarship.getAddress();
    const balanceBefore = await ethers.provider.getBalance(contractAddr);

    await expect(scholarship.connect(committee1).selectWinner())
      .to.emit(scholarship, "WinnerSelected");

    roundInfo = await scholarship.getRoundInfo();
    expect(roundInfo.hasWinner).to.equal(true);
    expect(roundInfo.currentPhase).to.equal(2n); // Closed

    // winner should be the applicant
    expect(roundInfo.winner).to.equal(applicant.address);

    const balanceAfter = await ethers.provider.getBalance(contractAddr);
    // all funds sent to winner
    expect(balanceAfter).to.equal(0n);
    expect(balanceBefore).to.be.greaterThan(0n);
  });

  it("allows committee to start next round after closing", async function () {
    const {
      scholarship,
      committee1,
      committee2,
      applicant,
      donor,
    } = await deployScholarshipFixture();

    // set up: single full round quickly

    // application
    await scholarship.connect(applicant).applyfor("ipfs://round1");

    // donate
    await scholarship.connect(donor).donate({ value: ethers.parseEther("0.5") });

    // start voting
    await scholarship.connect(committee1).startVoting();

    // vote
    await scholarship.connect(committee1).vote(1);
    await scholarship.connect(committee2).vote(1);

    // wait for applicationDuration + votingDuration if time check is enabled
    const applicationDuration = await scholarship.applicationDuration();
    const votingDuration = await scholarship.votingDuration();
    const totalWait = applicationDuration + votingDuration + 1n;

    await ethers.provider.send("evm_increaseTime", [Number(totalWait)]);
    await ethers.provider.send("evm_mine", []);

    // select winner
    await scholarship.connect(committee1).selectWinner();

    let roundInfo = await scholarship.getRoundInfo();
    expect(roundInfo.currentPhase).to.equal(2n); // Closed

    // start next round
    await expect(scholarship.connect(committee1).startNextRound())
      .to.emit(scholarship, "NewRoundStarted")
      .withArgs(2n);

    roundInfo = await scholarship.getRoundInfo();
    expect(roundInfo.round).to.equal(2n);
    expect(roundInfo.currentPhase).to.equal(0n); // Applications
    expect(roundInfo.appsCount).to.equal(0n);
  });

  it("allows an existing committee member to add a new committee member", async function () {
    const { scholarship, committee1, extraCommittee } =
      await deployScholarshipFixture();

    // non-committee cannot add
    await expect(
      scholarship.connect(extraCommittee).addCommitteeMember(extraCommittee.address)
    ).to.be.revertedWith("Only committee can add members");

    // committee can add new member
    await expect(
      scholarship.connect(committee1).addCommitteeMember(extraCommittee.address)
    )
      .to.emit(scholarship, "CommitteeMemberAdded")
      .withArgs(extraCommittee.address);

    expect(await scholarship.isCommittee(extraCommittee.address)).to.equal(true);
    expect(await scholarship.committeeCount()).to.equal(3n);
  });
});
