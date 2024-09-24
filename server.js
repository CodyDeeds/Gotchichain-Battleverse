require('dotenv').config();
const Web3 = require('web3');
const express = require('express');
const app = express();
const port = 3000;

// Middleware
app.use(express.json()); // Ensure this is applied before any routes

// Initialize Web3
const web3 = new Web3('https://polygon-mainnet.infura.io/v3/' + process.env.INFURA_PROJECT_ID);

// Account setup
const account = web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

// GLTR token setup
const gltrTokenAddress = '0x3801C3B3B5c98F88a9c9005966AA96aa440B9Afc';
const gltrTokenABI = [
    {
        "constant": true,
        "inputs": [],
        "name": "name",
        "outputs": [
            {
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": false,
        "inputs": [
            {
                "name": "_to",
                "type": "address"
            },
            {
                "name": "_value",
                "type": "uint256"
            }
        ],
        "name": "transfer",
        "outputs": [
            {
                "name": "",
                "type": "bool"
            }
        ],
        "payable": false,
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "decimals",
        "outputs": [
            {
                "name": "",
                "type": "uint8"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [],
        "name": "symbol",
        "outputs": [
            {
                "name": "",
                "type": "string"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "constant": true,
        "inputs": [
            {
                "name": "_owner",
                "type": "address"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "name": "balance",
                "type": "uint256"
            }
        ],
        "payable": false,
        "stateMutability": "view",
        "type": "function"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "name": "from",
                "type": "address"
            },
            {
                "indexed": true,
                "name": "to",
                "type": "address"
            },
            {
                "indexed": false,
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Transfer",
        "type": "event"
    }
];
const gltrTokenContract = new web3.eth.Contract(gltrTokenABI, gltrTokenAddress);

// Game state variables
let player1 = null;
let player2 = null;
let depositsConfirmed = false;

// Start game endpoint
app.post('/start_game', (req, res) => {
    const { player1: p1, player2: p2 } = req.body;
    player1 = p1;
    player2 = p2;
    depositsConfirmed = true;

    console.log("Player 1 Address: ", player1);
    console.log("Player 2 Address: ", player2);

    res.status(200).json({
        success: true,
        message: 'Game started',
        player1,
        player2
    });
});

// Check deposits endpoint
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

// Game over endpoint
app.post('/game_over', async (req, res) => {
    console.log("Request body: ", req.body);  // Debugging line
    const { winner } = req.body;

    console.log("Winner address received: ", winner);  // Debugging line

    if (!depositsConfirmed) {
        return res.status(400).json({ success: false, message: 'No game in progress.' });
    }

    try {
        // Send 200 GLTR to the winner
        await sendTokens(winner, 200);

        // Reset game state
        player1 = null;
        player2 = null;
        depositsConfirmed = false;

        res.json({ success: true, message: 'Winner paid and game reset.', result: "game_over_acknowledged" });
    } catch (error) {
        console.error('Error sending tokens:', error);
        res.status(500).json({ success: false, message: 'Failed to send tokens.' });
    }
});

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

    console.log('Transaction receipt:', receipt);
}

// Start the server
app.listen(port, () => {
    console.log(`Server listening at http://localhost:${port}`);
});
