import { expect, use } from 'chai';
import { solidity } from 'ethereum-waffle';

import * as hre from 'hardhat';
import { GYA } from '../types/ethers-contracts/GYA';
import { GYA__factory } from '../types/ethers-contracts/factories/GYA__factory';
import { KokiriNFT } from '../types/ethers-contracts/KokiriNFT';
import { KokiriNFT__factory } from '../types/ethers-contracts/factories/KokiriNFT__factory';
import { KokiriSales } from '../types/ethers-contracts/KokiriSales';
import { KokiriSales__factory } from '../types/ethers-contracts/factories/KokiriSales__factory';

const { ethers } = hre;

use(solidity);

const parseEther = (val) => {
    return ethers.utils.parseEther(val);
}

const toEther = (val) => {
    return ethers.utils.formatEther(val);
}

describe('Testing Kokiri NFT Market...', () => {
    let deployer;
    let account1;
    let account2;
    let beforeBalance;
    let gya: GYA;
    let gyaFactory: GYA__factory;
    let kokiriNFT: KokiriNFT;
    let kokiriNFTFactory: KokiriNFT__factory;
    let kokiriSales: KokiriSales;
    let kokiriSalesFactory: KokiriSales__factory;
    let tokenId1;
    let tokenId2;

    before(async () => {
        let accounts  = await ethers.getSigners();

        deployer = accounts[0];
        account1 = accounts[1];
        account2 = accounts[2];
        console.log(`Deployer => ${deployer.address}`);
        beforeBalance = await deployer.getBalance();
        console.log("Deployer before balance => ", ethers.utils.formatEther(beforeBalance));
        
        gyaFactory = new GYA__factory(deployer);
        gya = await gyaFactory.deploy(deployer.address);

        kokiriNFTFactory = new KokiriNFT__factory(deployer);
        kokiriNFT = await kokiriNFTFactory.deploy(deployer.address);

        kokiriSalesFactory = new KokiriSales__factory(deployer);
        kokiriSales = await kokiriSalesFactory.deploy(kokiriNFT.address, gya.address);

        console.log("GYA token address =>", gya.address);
        console.log("KokiriNFT address =>", kokiriNFT.address);
        console.log("KokiriSales address =>", kokiriSales.address);
        console.log('');
    });

    after(async () => {
        [ deployer ] = await ethers.getSigners();
        const afterBalance = await deployer.getBalance();
        console.log('');
        console.log("Deployer after balance => ", ethers.utils.formatEther(afterBalance));
        const cost = beforeBalance.sub(afterBalance);
        console.log("Test Cost: ", ethers.utils.formatEther(cost));
    });

    it('Distribute 100k GYAs to each accounts', async () => {
        const beforeBalance = await gya.balanceOf(deployer.address);
        await gya.transfer(account1.address, ethers.utils.parseEther('100000'));
        await gya.transfer(account2.address, ethers.utils.parseEther('100000'));
        expect(await gya.balanceOf(account1.address)).to.equal(ethers.utils.parseEther('100000'));
        expect(await gya.balanceOf(account2.address)).to.equal(ethers.utils.parseEther('100000'));
        const afterBalance = await gya.balanceOf(deployer.address);
        expect(afterBalance).to.equal(beforeBalance.sub(ethers.utils.parseEther('200000')));

        gya.approve(kokiriSales.address, parseEther('100000'));
        gya.connect(account1).approve(kokiriSales.address, parseEther('100000'));
        gya.connect(account2).approve(kokiriSales.address, parseEther('100000'));
    });

    it('Check mint permission, it should be shown unauthorized error', async () => {
        try {
            const tx = await kokiriNFT.connect(account1).mintNFT(account2.address, 'kokiri token NFT URI');
            expect(tx, "!authorized").to.be.undefined;
        } catch (err) {
            console.log(err.message);
        }
    });

    it('Mint 2 NFTs', async () => {
        const tx1 = await (await kokiriNFT.mintNFT(account1.address, 'https://localhost/kokiri-nft1')).wait();
        const tx2 = await (await kokiriNFT.mintNFT(account2.address, 'https://localhost/kokiri-nft2')).wait();
        tokenId1 = tx1.events[0].args.tokenId;
        tokenId2 = tx2.events[0].args.tokenId;
        expect(await kokiriNFT.tokenURI(tokenId1)).to.equal('https://localhost/kokiri-nft1');
        expect(await kokiriNFT.tokenURI(tokenId2)).to.equal('https://localhost/kokiri-nft2');
        expect(await kokiriNFT.ownerOf(tokenId1)).to.equal(account1.address);
        expect(await kokiriNFT.ownerOf(tokenId2)).to.equal(account2.address);
    });

    it('Transfer token', async () => {
        await kokiriNFT.connect(account1).transferNFT(account2.address, tokenId1);
        expect(await kokiriNFT.ownerOf(tokenId1)).to.equal(account2.address);
        await kokiriNFT.connect(account2).transferNFT(account1.address, tokenId1);
        expect(await kokiriNFT.ownerOf(tokenId1)).to.equal(account1.address);
    });

    it('Update token price', async () => {
        await kokiriSales.connect(account1).setTokenPrice(tokenId1, parseEther('30'));
        const price1 = await kokiriSales.tokenPrices(tokenId1);
        const price2 = (await kokiriSales.tokenSales(tokenId1)).price;
        expect(price1).to.equal(parseEther('30'));
        // expect(price1).to.equal(price2);
    });

    it('List to shop NFTs', async () => {
        await kokiriNFT.connect(account1).approve(kokiriSales.address, tokenId1);
        await kokiriSales.connect(account1).wantSale(tokenId1, parseEther('10'));
        await kokiriNFT.connect(account2).approve(kokiriSales.address, tokenId2);
        await kokiriSales.connect(account2).wantSale(tokenId2, parseEther('20'));
    });

    it('Update token price after listed market', async () => {
        await kokiriSales.connect(account1).setTokenPrice(tokenId1, parseEther('40'));
        const price1 = await kokiriSales.tokenPrices(tokenId1);
        const price2 = (await kokiriSales.tokenSales(tokenId1)).price;
        expect(price1).to.equal(parseEther('40'));
        expect(price1).to.equal(price2);
    });

    it('Get token info', async () => {
        const token = await kokiriSales.tokenSales(tokenId1);
        expect(token.owner).to.equal(account1.address);
        expect(token.price).to.equal(parseEther('40'));
    })

    it('Get token list', async () => {
        const tokens = await kokiriSales.salesListAll();
        await tokens.map(token => {
            console.log(`Id: ${token.id}, Owner: ${token.owner}, Price: ${toEther(token.price)}`);
        });
    });

    it('Purchase token', async () => {
        const price1 = await kokiriSales.tokenPrices(tokenId1);
        const price2 = await kokiriSales.tokenPrices(tokenId2);
        expect(price1).to.equal(parseEther('40'));
        expect(price2).to.equal(parseEther('20'));

        const beforeBalance1 = await gya.balanceOf(account1.address);
        const beforeBalance2 = await gya.balanceOf(account2.address);
        
        await kokiriSales.connect(account1).purchaseToken(tokenId2);
        
        const afterBalance1 = await gya.balanceOf(account1.address);
        const afterBalance2 = await gya.balanceOf(account2.address);

        expect(afterBalance1).to.equal(beforeBalance1.sub(parseEther('20')));
        expect(afterBalance2).to.equal(beforeBalance2.add(parseEther('20')));

        expect(await kokiriNFT.ownerOf(tokenId2)).to.equal(account1.address);
    });

    it('Get token list after purchased', async () => {
        const tokens = await kokiriSales.salesListAll();
        await tokens.map(token => {
            console.log(`Id: ${token.id}, Owner: ${token.owner}, Price: ${toEther(token.price)}`);
        });

        const mytokens = await kokiriSales.salesList(account1.address);
        await mytokens.map(token => {
            console.log(`My tokens => Id: ${token.id}, Price: ${toEther(token.price)}`);
        });
    });

    it('Remove sale', async () => {
        const before = await kokiriSales.salesIdList(account1.address);
        console.log("Sales token list before remved: ", before);
        await kokiriSales.removeSale(tokenId1);
        const after = await kokiriSales.salesIdList(account1.address);
        console.log("Sales token list after remved: ", after);
        // expect(after.length()).to.equal(before.length()-1);
    });

    it('My tokens', async () => {
        const tokens = await kokiriNFT.tokens(account1.address);
        await tokens.map(async token => {
            const tokenURI = await kokiriNFT.tokenURI(token);
            console.log(`tokenId: ${token}, tokenURI: ${tokenURI}`);
        });
    });
});