import * as hre from 'hardhat';
import { GYA } from '../types/ethers-contracts/GYA';
import { GYA__factory } from '../types/ethers-contracts/factories/GYA__factory';
import { KokiriNFT } from '../types/ethers-contracts/KokiriNFT';
import { KokiriNFT__factory } from '../types/ethers-contracts/factories/KokiriNFT__factory';
import { KokiriSales } from '../types/ethers-contracts/KokiriSales';
import { KokiriSales__factory } from '../types/ethers-contracts/factories/KokiriSales__factory';

require("dotenv").config();

const { ethers } = hre;

const sleep = (milliseconds, msg='') => {
    console.log(`Wait ${milliseconds} ms... (${msg})`);
    const date = Date.now();
    let currentDate = null;
    do {
      currentDate = Date.now();
    } while (currentDate - date < milliseconds);
}

const toEther = (val) => {
    return ethers.utils.formatEther(val);
}

async function deploy() {
    console.log((new Date()).toLocaleString());
    
    const [deployer] = await ethers.getSigners();
    
    console.log(
        "Deploying contracts with the account:",
        deployer.address
    );

    const beforeBalance = await deployer.getBalance();
    console.log("Account balance:", (await deployer.getBalance()).toString());

    const mainnet = process.env.NETWORK == "mainnet" ? true : false;
    const gyaAddress = mainnet ? process.env.GYA_MAIN : process.env.GYA_TEST
    const nftAddress = mainnet ? process.env.NFT_MAIN : process.env.NFT_TEST
    const salesAddress = mainnet ? process.env.SALES_MAIN : process.env.SALES_TEST

    const gyaFactory: GYA__factory = new GYA__factory(deployer);
    let gya: GYA = await gyaFactory.attach(gyaAddress).connect(deployer);
    if ("redeploy" && false) {
        gya = await gyaFactory.deploy(process.env.ADMIN);
        console.log(`Deployed GYA... (${gya.address})`);
    }
    const nftFactory: KokiriNFT__factory = new KokiriNFT__factory(deployer);
    let nft: KokiriNFT = await nftFactory.attach(nftAddress).connect(deployer);
    if ("redeploy" && false) {
        nft = await nftFactory.deploy(process.env.MINTER);
        console.log(`Deployed KokiriNFT... (${nft.address})`);
    }
    const salesFactory: KokiriSales__factory = new KokiriSales__factory(deployer);
    let sales: KokiriSales = salesFactory.attach(salesAddress).connect(deployer);
    if ("redeploy" && true) {
        sales = await salesFactory.deploy(nft.address, gya.address);
        console.log(`Deployed KokiriSales... (${sales.address})`);
    }

    console.log("Setting minter and admin...");
    await nft.setMinter('0xbC924332E2E7d8F2e9914aA0e8b325b90EA881EA');
    await sales.setAdmin('0xbC924332E2E7d8F2e9914aA0e8b325b90EA881EA');

    const afterBalance = await deployer.getBalance();
    console.log(
        "Deployed cost:",
         (beforeBalance.sub(afterBalance)).toString()
    );
}

deploy()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    })