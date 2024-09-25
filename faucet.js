require('dotenv').config();
const Web3 = require('web3');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const express = require('express');
const NodeWebcam = require('node-webcam');
const Jimp = require('jimp');
const QrCode = require('qrcode-reader');

// Initialize Web3
const web3 = new Web3('https://polygon-mainnet.infura.io/v3/' + process.env.INFURA_PROJECT_ID);

// Account setup
const account = web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

// GLTR token setup
const gltrTokenAddress = '0x3801C3B3B5c98F88a9c9005966AA96aa440B9Afc';
const gltrTokenABI = [
    // ... (abbreviated for brevity, use the same ABI as in server.js)
];
const gltrTokenContract = new web3.eth.Contract(gltrTokenABI, gltrTokenAddress);

// Track addresses that have received tokens
let faucetRecipients = {};

// Path to the faucet recipients file
const faucetRecipientsFilePath = path.join(__dirname, 'faucetRecipients.json');

// Function to save faucet recipients to a file
function saveFaucetRecipientsToFile() {
    fs.writeFileSync(faucetRecipientsFilePath, JSON.stringify(faucetRecipients, null, 2));
}

// Function to load faucet recipients from a file
function loadFaucetRecipientsFromFile() {
    if (fs.existsSync(faucetRecipientsFilePath)) {
        const data = fs.readFileSync(faucetRecipientsFilePath);
        faucetRecipients = JSON.parse(data);
    }
}

// Load faucet recipients when the server starts
loadFaucetRecipientsFromFile();

// Function to send tokens
async function sendTokens(toAddress, amount) {
    const decimals = await gltrTokenContract.methods.decimals().call();
    const amountToSend = web3.utils.toBN(amount).mul(web3.utils.toBN(10).pow(web3.utils.toBN(decimals)));

    const tx = {
        from: account.address,
        to: gltrTokenAddress,
        data: gltrTokenContract.methods.transfer(toAddress, amountToSend).encodeABI(),
        gasPrice: await web3.eth.getGasPrice(),
        gas: 100000,
    };

    const signedTx = await web3.eth.accounts.signTransaction(tx, process.env.PRIVATE_KEY);
    const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);

    console.log('GLTR Transaction receipt:', receipt);
}

// Function to send MATIC
async function sendMatic(toAddress, amount) {
    const tx = {
        from: account.address,
        to: toAddress,
        value: web3.utils.toWei(amount.toString(), 'ether'),
        gasPrice: await web3.eth.getGasPrice(),
        gas: 21000,
    };

    const signedTx = await web3.eth.accounts.signTransaction(tx, process.env.PRIVATE_KEY);
    const receipt = await web3.eth.sendSignedTransaction(signedTx.rawTransaction);

    console.log('MATIC Transaction receipt:', receipt);
}

// Faucet function
async function faucet(address) {
    if (faucetRecipients[address]) {
        console.log('Address has already received tokens.');
        return;
    }

    try {
        // Send 500 GLTR tokens
        const gltrAmount = 500;
        await sendTokens(address, gltrAmount);

        // Send 0.2 MATIC
        const maticAmount = 0.2;
        await sendMatic(address, maticAmount);

        // Mark address as having received tokens
        faucetRecipients[address] = true;
        saveFaucetRecipientsToFile();

        console.log('Tokens sent successfully to:', address);
    } catch (error) {
        console.error('Error sending tokens:', error);
    }
}

// Configure webcam
const webcamOptions = {
    width: 1280,
    height: 720,
    quality: 100,
    delay: 0,
    saveShots: true,
    output: 'jpeg',
    device: false,
    callbackReturn: 'location',
    verbose: false
};

const Webcam = NodeWebcam.create(webcamOptions);

// Function to scan QR code
function scanQRCode() {
    const imagePath = path.join(__dirname, 'public', 'qr_code.jpg');
    console.log(`Capturing image to: ${imagePath}`); // Log the image path
    Webcam.capture(imagePath, async (err, data) => {
        if (err) {
            console.error('Error capturing image:', err);
            return;
        }

        try {
            const image = await Jimp.read(data);
            const qr = new QrCode();

            qr.callback = async (err, value) => {
                if (err) {
                    console.error('Error reading QR code:', err);
                    return;
                }

                const address = value.result;
                console.log('QR Code scanned address:', address);

                // Send request to faucet function
                await faucet(address);
            };

            qr.decode(image.bitmap);
        } catch (error) {
            console.error('Error processing image:', error);
        }
    });
}

// Periodically scan for QR codes
setInterval(scanQRCode, 5000); // Scan every 5 seconds

// Load initial data
loadFaucetRecipientsFromFile();

// Set up Express server to serve the images
const app = express();
const port = 3002;

app.use(express.static(path.join(__dirname, 'public')));

app.listen(port, () => {
    console.log(`Faucet server listening at http://localhost:${port}`);
});
