require('dotenv').config();
const Web3 = require('web3'); // Correct import statement
const express = require('express');
const app = express();
const port = 3000;

const web3 = new Web3('wss://mainnet.infura.io/ws/v3/' + process.env.INFURA_PROJECT_ID);
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

const account = web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

app.use(express.json());

app.post('/distribute_rewards', async (req, res) => {
    console.log('Received request to distribute rewards'); // Added to confirm the endpoint is hit
    try {
        const { winnerAddress } = req.body;
        console.log(`Attempting to transfer 200 GLTR to ${winnerAddress}`); // Output before attempting transfer
        const amount = web3.utils.toWei('200', 'ether');
        const receipt = await gltrTokenContract.methods.transfer(winnerAddress, amount).send({ from: account.address });
        console.log('Transfer successful:', receipt); // Output the receipt on successful transfer
        res.json({ success: true, receipt });
    } catch (error) {
        console.error('Error during transfer:', error); // Output errors if transfer fails
        res.status(500).json({ success: false, error: error.message });
    }
});

let depositsConfirmed = false;

// Endpoint to check for deposits
app.get('/check_deposits', (req, res) => {
    if (depositsConfirmed) {
        res.json({ result: "deposits_confirmed" });
    } else {
        res.json({ result: "waiting_for_deposits" });
    }
});

// Update the start_game endpoint to set depositsConfirmed to true
app.post('/start_game', (req, res) => {
    const { player1, player2 } = req.body;
    console.log(`Starting game with Player 1: ${player1} and Player 2: ${player2}`);
    depositsConfirmed = true;
    res.status(200).json({ success: true, message: 'Game started' });
});

let logs = [];

app.post('/log', (req, res) => {
    const { message } = req.body;
    logs.push(message);
    console.log(message);
    res.status(200).json({ success: true, message: 'Log received' });
});

app.get('/logs', (req, res) => {
    res.json({ logs });
});

app.listen(port, () => {
    console.log(`Server listening at http://localhost:${port}`);
    console.log('Server is up and running. Waiting for deposits...'); // Added printout to confirm server is running
});