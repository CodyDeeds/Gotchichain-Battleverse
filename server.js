require('dotenv').config();
const Web3 = require('web3');
const express = require('express');
const axios = require('axios');
const fs = require('fs');
const path = require('path');
const app = express();
const statusApp = express(); // New Express instance for game status
const port = 3000;
const statusPort = 3001; // New port for game status

// Middleware
app.use(express.json()); // Ensure this is applied before any routes
statusApp.use(express.json()); // Middleware for the status server

// Initialize Web3
const web3 = new Web3('https://polygon-mainnet.infura.io/v3/' + process.env.INFURA_PROJECT_ID);

// Account setup
const account = web3.eth.accounts.privateKeyToAccount(process.env.PRIVATE_KEY);
web3.eth.accounts.wallet.add(account);
web3.eth.defaultAccount = account.address;

// GLTR token setup
const gltrTokenAddress = '0x3801C3B3B5c98F88a9c9005966AA96aa440B9Afc';
// GLTR Token ABI (abbreviated for brevity)
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
let player1Bet = 0;
let player2Bet = 0;
let depositsConfirmed = false;
let gameInProgress = false; // Corrected variable usage

// Track player winnings
let playerWinnings = {};

// Path to the winnings file
const winningsFilePath = path.join(__dirname, 'playerWinnings.json');

// Function to save player winnings to a file
function saveWinningsToFile() {
    fs.writeFileSync(winningsFilePath, JSON.stringify(playerWinnings, null, 2));
}

// Function to load player winnings from a file
function loadWinningsFromFile() {
    if (fs.existsSync(winningsFilePath)) {
        const data = fs.readFileSync(winningsFilePath);
        playerWinnings = JSON.parse(data);
    }
}

// Load winnings when the server starts
loadWinningsFromFile();

// Player ready endpoint
app.post('/player_ready', (req, res) => {
    const { player, address, amount } = req.body;

    if (player === 'player1') {
        player1 = address;
        player1Bet = amount;
        console.log(`Player 1 Address: ${player1} is ready with bet: ${player1Bet}`);
    } else if (player === 'player2') {
        player2 = address;
        player2Bet = amount;
        console.log(`Player 2 Address: ${player2} is ready with bet: ${player2Bet}`);
    }

    if (player1 && player2) {
        depositsConfirmed = true;
        gameInProgress = true; // Corrected variable usage
        console.log('Both players are now present. Starting the game...');
        // Responding directly since starting the game is handled elsewhere
        res.status(200).json({
            success: true,
            message: 'Game started',
            player1,
            player2,
            player1Bet,
            player2Bet
        });
    } else {
        res.status(200).json({
            success: true,
            message: `${player} is ready`,
            player1,
            player2,
            player1Bet,
            player2Bet
        });
    }
});

// Start game endpoint
app.post('/start_game', (req, res) => {
    const { player1: p1, player2: p2, player1Bet: p1Bet, player2Bet: p2Bet } = req.body;
    player1 = p1;
    player2 = p2;
    player1Bet = p1Bet;
    player2Bet = p2Bet;
    depositsConfirmed = true;
    gameInProgress = true; // Corrected variable usage

    console.log("Player 1 Address: ", player1, " is ready with bet: ", player1Bet);
    console.log("Player 2 Address: ", player2, " is ready with bet: ", player2Bet);

    res.status(200).json({
        success: true,
        message: 'Game started',
        player1,
        player2,
        player1Bet,
        player2Bet
    });
});

// Check deposits endpoint
app.get('/check_deposits', (req, res) => {
    if (player1 && !player2) {
        res.json({
            result: "player1_ready",
            player1,
            player1Bet
        });
    } else if (player1 && player2) {
        res.json({
            result: "deposits_confirmed",
            player1,
            player2,
            player1Bet,
            player2Bet
        });
    } else {
        res.json({ result: "waiting_for_deposits" });
    }
});

// Game status endpoint on a new port
statusApp.get('/game_status', (req, res) => {
    console.log('Received /game_status request');
    res.json({
        gameInProgress: gameInProgress // Corrected variable usage
    });
});

// Addresses for prize pool and DAO
const prizePoolAddress = '0xf6F32187f249912e516c83Ebfc6305bb5bFde307';
const daoAddress = '0xb208f8BB431f580CC4b216826AFfB128cd1431aB';

// Prize pool amount
let prizePoolAmount = 0;

// Function to calculate distribution amounts
function calculateDistribution(prizePool) {
    const distribution = [];
    const percentages = [0.4, 0.3, 0.15, 0.1, 0.05]; // Example distribution percentages
    percentages.forEach(percentage => {
        distribution.push(prizePool * percentage);
    });
    return distribution;
}

// Game over endpoint
app.post('/game_over', async (req, res) => {
    console.log("Request body: ", req.body);  // Debugging line
    const { winner } = req.body;

    console.log("Winner address received: ", winner);  // Debugging line

    if (!depositsConfirmed) {
        return res.status(400).json({ success: false, message: 'No game in progress.' });
    }

    if (player1 === player2) {
        return res.status(400).json({ success: false, message: 'Players cannot be the same.' });
    }

    try {
        const minBet = Math.min(player1Bet, player2Bet);
        const totalPayout = minBet * 2;
        const refundAmount = Math.abs(player1Bet - player2Bet);

        // Calculate tax only on the amount above the base 200
        const taxableAmount = Math.max(0, totalPayout - 200);
        const prizePoolTax = taxableAmount * 0.20;
        const daoTax = taxableAmount * 0.05;
        const netPayout = totalPayout - prizePoolTax - daoTax;

        // Log the after-tax winnings
        console.log(`Winner: ${winner}, Amount Won (after tax): ${netPayout}`);

        // Send the net payout to the winner
        await sendTokens(winner, netPayout);

        // Send the prize pool tax
        await sendTokens(prizePoolAddress, prizePoolTax);

        // Send the DAO tax
        await sendTokens(daoAddress, daoTax);

        // Refund the remaining amount to the loser if any
        const loser = winner === player1 ? player2 : player1;
        if (refundAmount > 0) {
            await sendTokens(loser, refundAmount);
        }

        // Update player winnings
        if (!playerWinnings[winner]) {
            playerWinnings[winner] = 0;
        }
        playerWinnings[winner] += netPayout;

        // Save winnings to file
        saveWinningsToFile();

        // Update prize pool amount
        prizePoolAmount += prizePoolTax;

        // Reset game state
        player1 = null;
        player2 = null;
        player1Bet = 0;
        player2Bet = 0;
        depositsConfirmed = false;
        gameInProgress = false; // Ensure gameInProgress is reset

        res.json({ success: true, message: 'Winner paid and game reset.', result: "game_over_acknowledged", amount_won: netPayout, amount_bet: minBet });
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

// Leaderboard endpoint
app.get('/leaderboard', (req, res) => {
    const sortedWinnings = Object.entries(playerWinnings)
        .sort(([, a], [, b]) => b - a)
        .slice(0, 5)
        .map(([address, winnings]) => ({ address, winnings }));

    const distribution = calculateDistribution(prizePoolAmount);

    res.json({ leaderboard: sortedWinnings, prizePool: prizePoolAmount, distribution });
});

// Serve leaderboard HTML
app.get('/leaderboard.html', (req, res) => {
    res.sendFile(path.join(__dirname, 'leaderboard.html'));
});

// Start the main server
app.listen(port, () => {
    console.log(`Server listening at http://localhost:${port}`);
});

// Start the status server
statusApp.listen(statusPort, () => {
    console.log(`Status server listening at http://localhost:${statusPort}`);
});
