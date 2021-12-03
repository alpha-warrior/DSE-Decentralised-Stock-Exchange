const Netflix = artifacts.require("Netflix");
const EthCrypto = require("eth-crypto");
const web3 = require("web3");
const buyerid = EthCrypto.createIdentity();
const sellerid = EthCrypto.createIdentity();
const bpublic = buyerid.publicKey;
const bprivate = buyerid.privateKey;
const spublic = sellerid.publicKey;
const sprivate = sellerid.privateKey;
const item1 = "screen1";
const item2 = "screen2";

contract("Netflix", (accounts) => {
    let [buyer, seller] = accounts;
    it("simulates a whole transaction", async () => {
        const contractInstance = await Netflix.new();
        console.log("Starting test");
        let avail = await contractInstance.viewAvailItems({from: buyer});
        console.log(avail);
        console.log("Listing new item.")
        await contractInstance.listItem("screen 1", "new Netflix Screen", 10, {from: seller});
        await contractInstance.listItem("screen 2", "new Netflix Screen", 5, {from: seller});
        avail = await contractInstance.viewAvailItems({from: buyer});
        console.log(avail);
        await contractInstance.buyItem(0, bpublic, {from: buyer, value:10});
        let pk = await contractInstance.get_public_key(0, {from: seller});
        assert.equal(pk, bpublic);
        const encrypted = await EthCrypto.encryptWithPublicKey(
            pk,
            item1
          );
        console.log("Encrypted string:")
        console.log(encrypted)
        await contractInstance.send_encrypted_string(EthCrypto.cipher.stringify(encrypted) ,0, {from: seller});
        let es = await contractInstance.get_encrypted_string(0, {from: buyer});
        assert.equal(es, EthCrypto.cipher.stringify(encrypted));
        const decrypted = await EthCrypto.decryptWithPrivateKey(
            bprivate,
            EthCrypto.cipher.parse(es)
          );
        console.log("Decrypted string:")
        console.log(decrypted)
        assert.equal(decrypted, item1);
        
    })
})
