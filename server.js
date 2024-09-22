require('dotenv').config();
const Web3 = require('web3');
const express = require('express');
const app = express();
const port = 3000;

const web3 = new Web3('wss://mainnet.infura.io/ws/v3/' + process.env.INFURA_PROJECT_ID);
const gltrTokenAddress = '0x3801C3B3B5c98F88a9c9005966AA96aa440B9Afc';
const gltrTokenABI = [ /* Token ABI */ ];

const gltrTokenContract = new web3.eth.Contract(gltrTokenABI, gltrTokenAddress);

const account = web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

app.use(express.json());

let depositsConfirmed = false;
let logs = [];
let player1 = null;
let player2 = null;

app.post('/start_game', (req, res) => {
    player1 = req.body.player1;
    player2 = req.body.player2;
    const logMessage = `Game started with Player 1: ${player1}, Player 2: ${player2}`;
    logs.push(logMessage);
    depositsConfirmed = true;

    // Log the addresses to the server console
    console.log("Player 1 Address: ", player1);
    console.log("Player 2 Address: ", player2);

    // Extract wallet information for qr_scene.gd
    const walletInfo = {
        privateKey: process.env.PRIVATE_KEY,
        address: account.address
    };

    res.status(200).json({ 
        success: true, 
        message: 'Game started', 
        player1, 
        player2, 
        walletInfo 
    });
});

app.get('/check_deposits', (req, res) => {
    if (depositsConfirmed) {
        res.json({ 
            result: "deposits_confirmed", 
            player1, 
            player2 
        });
    } else {
        res.json({ result: "waiting_for_deposits" });
    }
});

app.listen(port, () => {
    console.log(`Server listening at http://localhost:${port}`);
});
