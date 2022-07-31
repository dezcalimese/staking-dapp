const { ethers } = require("hardhat");

async function main() {
    [signer1, signer2] = await ethers.getSigners();

    const Staking = await ethers.getContractFactory('Staking', signer1);
    staking = await Staking.deploy({
        value: ethers.utils.parseEther('10')
    });

    console.log("Staking contract deployed to:", staking.address, "by", signer1.address);

    const provider = waffle.provider;
    let data;
    let transaction;
    let receipt;
    let block;
    let newUnlockDate;

    data = { value: ethers.utils.parseEther('0.5') }
    transaction = await staking.connect(signer2).stakeEther(30, data);

    data = { value: ethers.utils.parseEther('1') }
    transaction = await staking.connect(signer2).stakeEther(180, data);

    data = { value: ethers.utils.parseEther('1.75') }
    transaction = await staking.connect(signer2).stakeEther(180, data);

    data = { value: ethers.utils.parseEther('5') }
    transaction = await staking.connect(signer2).stakeEther(90, data);
    receipt = await transaction.wait();
    block = await provider.getBlock(receipt.blockNumber);
    newUnlockDate = block.timestamp - (60 * 60 * 24 * 100);
    await staking.connect(signer1).changeUnlockDate(3, newUnlockDate);

    data = { value: ethers.utils.parseEther('1.75') }
    transaction = await staking.connect(signer2).stakeEther(180, data);
    receipt = transaction.wait();
    block = await provider.getBlock(receipt.blockNumber);
    newUnlockDate = block.timestamp - (60 * 60 * 24 * 100);
    await staking.connect(signer1).changeUnlockDate(4, newUnlockDate);

}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

/* 
When deploying this contract again, this first contract will change 
so make sure to update this in the frontend

Example after running yarn hardhat run --network localhost scripts/1_deploy.js
Staking contract deployed to: 0x5FbDB2315678afecb367f032d93F642f64180aa3 by 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266
*/ 