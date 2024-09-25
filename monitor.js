require('dotenv').config();
const Web3 = require('web3');
const axios = require('axios');

// Initialize Web3 with Polygon Mainnet via Infura WebSocket
const web3 = new Web3(`wss://polygon-mainnet.infura.io/ws/v3/${process.env.INFURA_PROJECT_ID}`);

// Target address to monitor for incoming GLTR transfers
const targetAddress = '0x1d960A270a71Ce1448BA4E1D00af73EA29A994d3'.toLowerCase();

// GLTR Token contract address
const gltrTokenAddress = '0x3801C3B3B5c98F88a9c9005966AA96aa440B9Afc'.toLowerCase();

// GLTR Token ABI
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

// Initialize the GLTR token contract
const gltrTokenContract = new web3.eth.Contract(gltrTokenABI, gltrTokenAddress);

// State Variables
let player1 = null;
let player2 = null;
let player1Bet = 0;
let player2Bet = 0;
let tokenDecimals;
let gameInProgress = false; // Added variable to track game progress

// Helper Functions
async function getTokenDecimals() {
    try {
        const decimals = await gltrTokenContract.methods.decimals().call();
        return parseInt(decimals, 10);
    } catch (error) {
        console.error('Error getting token decimals:', error);
        return 18; // Default value
    }
}

function handleTransferEvent(event) {
    const { from, to, value } = event.returnValues;

    // Convert value from raw units to GLTR
    const amountBN = web3.utils.toBN(value);
    const decimalsBN = web3.utils.toBN(10).pow(web3.utils.toBN(tokenDecimals));
    const amount = amountBN.div(decimalsBN).toString();

    console.log(`Transfer detected: ${amount} GLTR from ${from} to ${to}`);

    // Check if the transfer is to the target address
    if (to.toLowerCase() === targetAddress) {
        console.log('Transfer to target address confirmed.');

        // Check if the amount is at least 100 GLTR
        if (parseFloat(amount) >= 100) {
            console.log(`Amount is ${amount} GLTR.`);

            if (!gameInProgress) {
                // Assign Player 1 if not already assigned
                if (!player1) {
                    player1 = from;
                    player1Bet = parseFloat(amount);
                    console.log(`Player 1 deposited ${amount} GLTR: ${from} is ready.`);
                    axios.post('http://localhost:3000/player_ready', { player: 'player1', address: player1, amount: player1Bet })
                        .then(response => {
                            console.log('Game server notified successfully:', response.data);
                        })
                        .catch(error => {
                            console.error('Failed to notify game server:', error);
                        });
                }
                // Assign Player 2 if not already assigned and the sender is different from Player 1
                else if (!player2 && from.toLowerCase() !== player1.toLowerCase()) {
                    player2 = from;
                    player2Bet = parseFloat(amount);
                    console.log(`Player 2 deposited ${amount} GLTR: ${from} is ready.`);
                    console.log('Both players are now present. Initiating startGame function.');
                    axios.post('http://localhost:3000/player_ready', { player: 'player2', address: player2, amount: player2Bet })
                        .then(response => {
                            console.log('Game server notified successfully:', response.data);
                            startGame(); // Start the game
                        })
                        .catch(error => {
                            console.error('Failed to notify game server:', error);
                        });
                }
            } else {
                console.log('Game is in progress. Ignoring new deposits.');
            }
        } else {
            console.log(`Deposit of ${amount} GLTR from ${from} does not meet the minimum required amount.`);
        }
    } else {
        console.log('Transfer not to target address. Ignoring.');
    }
}

function subscribeToTransferEvents() {
    gltrTokenContract.events.Transfer({
        filter: { to: targetAddress },
        fromBlock: 'latest'
    })
    .on('connected', function(subscriptionId){
        console.log('Subscription established. ID:', subscriptionId);
    })
    .on('data', handleTransferEvent)
    .on('error', function(error) {
        console.error('Error with event listener:', error);
        // Attempt to reconnect after a delay
        setTimeout(() => {
            console.log('Attempting to reconnect to event subscriptions...');
            subscribeToTransferEvents();
        }, 10000); // Wait 10 seconds before reconnecting
    });
}

function startGame() {
    console.log('Starting the game...');
    axios.post('http://localhost:3000/start_game', { player1, player2, player1Bet, player2Bet })
        .then(response => {
            console.log('Game server notified successfully:', response.data);
            gameInProgress = true; // Set game in progress
        })
        .catch(error => {
            console.error('Failed to notify game server:', error);
        });
}

function resetGameState() {
    player1 = null;
    player2 = null;
    player1Bet = 0;
    player2Bet = 0;
    gameInProgress = false; // Ensure gameInProgress is reset
    console.log('Game state reset. Ready for the next game.');
}

// Function to check if the game is over
async function checkGameOver() {
    if (gameInProgress) {
        try {
            console.log('Checking game status...');
            const response = await axios.get('http://localhost:3001/game_status'); // Updated port
            console.log('Game status response:', response.data);
            if (!response.data.gameInProgress) {
                console.log('Game is over. Resetting game state.');
                resetGameState();
            }
        } catch (error) {
            console.error('Error checking game status:', error);
            // Retry logic
            setTimeout(checkGameOver, 5000); // Retry after 5 seconds
        }
    }
}

// Periodically check if the game is over
setInterval(checkGameOver, 5000); // check every 5 seconds

// Initialization
(async () => {
    try {
        tokenDecimals = await getTokenDecimals();
        console.log(`GLTR Token Decimals: ${tokenDecimals}`);
        subscribeToTransferEvents();
    } catch (error) {
        console.error('Initialization failed:', error);
        process.exit(1);
    }
})();
