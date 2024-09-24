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
let tokenDecimals;

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

        // Check if the amount is exactly 100 GLTR
        if (parseFloat(amount) === 100) {
            console.log('Amount is exactly 100 GLTR.');

            // Assign Player 1 if not already assigned
            if (!player1) {
                player1 = from;
                console.log(`Player 1 deposited 100 GLTR: ${from}`);
            }
            // Assign Player 2 if not already assigned and the sender is different from Player 1
            else if (!player2 && from.toLowerCase() !== player1.toLowerCase()) {
                player2 = from;
                console.log(`Player 2 deposited 100 GLTR: ${from}`);
                console.log('Both players are now present. Initiating startGame function.');
                startGame();
            }
        } else {
            console.log(`Deposit of ${amount} GLTR from ${from} does not meet the required amount.`);
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
    axios.post('http://localhost:3000/start_game', { player1, player2 })
        .then(response => {
            console.log('Game server notified successfully:', response.data);
            // Reset the game state after notifying the server
            resetGameState();
        })
        .catch(error => {
            console.error('Failed to notify game server:', error);
        });
}

function resetGameState() {
    player1 = null;
    player2 = null;
    console.log('Game state reset. Ready for the next game.');
}

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
