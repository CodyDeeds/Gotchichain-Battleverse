// monitor.js

require('dotenv').config();
const Web3 = require('web3');
const axios = require('axios');

// === Configuration === //

// Ensure INFURA_PROJECT_ID is set in environment variables
if (!process.env.INFURA_PROJECT_ID) {
    console.error('❌ ERROR: INFURA_PROJECT_ID is not set in the environment variables.');
    process.exit(1);
}

// Initialize Web3 with Polygon Mainnet via Infura WebSocket
const web3 = new Web3(`wss://polygon-mainnet.infura.io/ws/v3/${process.env.INFURA_PROJECT_ID}`);

// Target address to monitor for incoming GLTR transfers
const targetAddress = '0x1d960A270a71Ce1448BA4E1D00af73EA29a994d3'.toLowerCase();

// GLTR Token contract address
const gltrTokenAddress = '0x3801c3b3b5c98f88a9c9005966aa96aa440b9afc'.toLowerCase();

// GLTR Token ABI (Complete ABI as provided)
const gltrTokenABI = [
    {
        "inputs": [],
        "stateMutability": "nonpayable",
        "type": "constructor"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "owner",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "spender",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Approval",
        "type": "event"
    },
    {
        "anonymous": false,
        "inputs": [
            {
                "indexed": true,
                "internalType": "address",
                "name": "from",
                "type": "address"
            },
            {
                "indexed": true,
                "internalType": "address",
                "name": "to",
                "type": "address"
            },
            {
                "indexed": false,
                "internalType": "uint256",
                "name": "value",
                "type": "uint256"
            }
        ],
        "name": "Transfer",
        "type": "event"
    },
    {
        "inputs": [],
        "name": "DOMAIN_SEPARATOR",
        "outputs": [
            {
                "internalType": "bytes32",
                "name": "",
                "type": "bytes32"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "owner",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "spender",
                "type": "address"
            }
        ],
        "name": "allowance",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "spender",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "approve",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "account",
                "type": "address"
            }
        ],
        "name": "balanceOf",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "decimals",
        "outputs": [
            {
                "internalType": "uint8",
                "name": "",
                "type": "uint8"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "spender",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "subtractedValue",
                "type": "uint256"
            }
        ],
        "name": "decreaseAllowance",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "spender",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "addedValue",
                "type": "uint256"
            }
        ],
        "name": "increaseAllowance",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "name",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "owner",
                "type": "address"
            }
        ],
        "name": "nonces",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "owner",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "spender",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "value",
                "type": "uint256"
            },
            {
                "internalType": "uint256",
                "name": "deadline",
                "type": "uint256"
            },
            {
                "internalType": "uint8",
                "name": "v",
                "type": "uint8"
            },
            {
                "internalType": "bytes32",
                "name": "r",
                "type": "bytes32"
            },
            {
                "internalType": "bytes32",
                "name": "s",
                "type": "bytes32"
            }
        ],
        "name": "permit",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "_token",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "_value",
                "type": "uint256"
            }
        ],
        "name": "recoverERC20",
        "outputs": [],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "symbol",
        "outputs": [
            {
                "internalType": "string",
                "name": "",
                "type": "string"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [],
        "name": "totalSupply",
        "outputs": [
            {
                "internalType": "uint256",
                "name": "",
                "type": "uint256"
            }
        ],
        "stateMutability": "view",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "recipient",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "transfer",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    },
    {
        "inputs": [
            {
                "internalType": "address",
                "name": "sender",
                "type": "address"
            },
            {
                "internalType": "address",
                "name": "recipient",
                "type": "address"
            },
            {
                "internalType": "uint256",
                "name": "amount",
                "type": "uint256"
            }
        ],
        "name": "transferFrom",
        "outputs": [
            {
                "internalType": "bool",
                "name": "",
                "type": "bool"
            }
        ],
        "stateMutability": "nonpayable",
        "type": "function"
    }
];

// Initialize the GLTR token contract
const gltrTokenContract = new web3.eth.Contract(gltrTokenABI, gltrTokenAddress);

// === State Variables === //

let player1 = null;
let player2 = null;
let tokenDecimals;

// === Logging === //

console.log('🔗 Connecting to Polygon network via Infura:', `wss://polygon-mainnet.infura.io/ws/v3/${process.env.INFURA_PROJECT_ID}`);
console.log('📄 Listening for Transfer events on contract:', gltrTokenAddress);

// === Helper Functions === //

/**
 * Fetches the number of decimals the GLTR token uses.
 * @returns {Promise<number>} The number of decimals.
 */
async function getTokenDecimals() {
    if (gltrTokenContract.methods.decimals) {
        try {
            const decimals = await gltrTokenContract.methods.decimals().call();
            return parseInt(decimals, 10);
        } catch (error) {
            console.error('❌ Error calling decimals method:', error);
            // Fallback to a default value
            return 18; // Common default for ERC-20 tokens
        }
    } else {
        console.warn('⚠️ Decimals method not found in ABI. Using default decimals value.');
        return 18; // Replace with actual decimals if known
    }
}

/**
 * Handles incoming Transfer events.
 * @param {Object} event The Transfer event object.
 */
function handleTransferEvent(event) {
    const { from, to, value } = event.returnValues;

    // Convert value from raw units to GLTR
    const amountBN = web3.utils.toBN(value);
    const decimalsBN = web3.utils.toBN(10).pow(web3.utils.toBN(tokenDecimals));
    const amount = amountBN.div(decimalsBN).toString(); // Assuming amount is an integer

    const logMessage = `\n📅 [${new Date().toISOString()}] Transfer detected: ${amount} GLTR from ${from} to ${to}\n🔢 Raw value: ${value}\n✅ Calculated amount: ${amount} GLTR`;
    console.log(logMessage);
    sendLog(logMessage);

    // Check if the transfer is to the target address
    if (to.toLowerCase() === targetAddress) {
        const targetLogMessage = '✅ Transfer to target address confirmed.';
        console.log(targetLogMessage);
        sendLog(targetLogMessage);

        // Check if the amount is exactly 100 GLTR
        if (parseFloat(amount) === 100) {
            const amountLogMessage = '✅ Amount is exactly 100 GLTR.';
            console.log(amountLogMessage);
            sendLog(amountLogMessage);

            // Assign Player 1 if not already assigned
            if (!player1) {
                player1 = from;
                const player1LogMessage = `🏆 Player 1 deposited 100 GLTR: ${from}`;
                console.log(player1LogMessage);
                sendLog(player1LogMessage);
            }
            // Assign Player 2 if not already assigned and the sender is different from Player 1
            else if (!player2 && from.toLowerCase() !== player1.toLowerCase()) {
                player2 = from;
                const player2LogMessage = `🏅 Player 2 deposited 100 GLTR: ${from}\n🎮 Both players are now present. Initiating startGame function.`;
                console.log(player2LogMessage);
                sendLog(player2LogMessage);
                startGame();
            }
        } else {
            const amountMismatchLogMessage = `⚠️ Deposit of ${amount} GLTR from ${from} does not meet the required amount for a game start.`;
            console.log(amountMismatchLogMessage);
            sendLog(amountMismatchLogMessage);
        }
    } else {
        const ignoreLogMessage = '🚫 Transfer not to target address. Ignoring.';
        console.log(ignoreLogMessage);
        sendLog(ignoreLogMessage);
    }
}

/**
 * Subscribes to Transfer events emitted by the GLTR token contract.
 */
function subscribeToTransferEvents() {
    gltrTokenContract.events.Transfer({
        filter: { to: targetAddress },
        fromBlock: 'latest'
    })
    .on('connected', function(subscriptionId){
        console.log('🔗 Subscription established. ID:', subscriptionId);
    })
    .on('data', handleTransferEvent)
    .on('changed', function(event){
        console.log('🔄 Event changed:', event);
    })
    .on('error', function(error, receipt) {
        console.error('❌ Error with event listener:', error);
        if (receipt) console.log('📄 Receipt:', receipt);
        // Attempt to reconnect after a delay
        setTimeout(() => {
            console.log('🔄 Attempting to reconnect to event subscriptions...');
            subscribeToTransferEvents();
        }, 10000); // Wait 10 seconds before reconnecting
    });
}

/**
 * Initiates the game by notifying the game server.
 */
function startGame() {
    console.log('🚀 Starting the game...');
    axios.post('http://localhost:3000/start_game', { player1, player2 })
        .then(response => {
            console.log('✅ Game server notified successfully:', response.data);
            // Notify Godot game to start
            axios.post('http://localhost:3000/start_game', { player1, player2 })
                .then(response => {
                    console.log('✅ Godot game notified successfully:', response.data);
                })
                .catch(error => {
                    console.error('❌ Failed to notify Godot game:', error);
                });
        })
        .catch(error => {
            console.error('❌ Failed to notify game server:', error);
        });
}

function sendLog(message) {
    axios.post('http://localhost:3000/log', { message })
        .then(response => {
            console.log('Log sent successfully:', response.data);
        })
        .catch(error => {
            console.error('Failed to send log:', error);
        });
}

// === Initialization === //

(async () => {
    try {
        tokenDecimals = await getTokenDecimals();
        console.log(`📊 GLTR Token Decimals: ${tokenDecimals}`);
        subscribeToTransferEvents();
    } catch (error) {
        console.error('❌ Initialization failed:', error);
        process.exit(1);
    }
})();

// === Optional: Polling Functionality === //

// To conserve API calls and adhere to your limits, polling is removed.
// If you need to implement polling in the future, consider optimizing its frequency and usage.

// /**
//  * Checks for new ETH deposits to the target address every 30 seconds.
//  */
// async function checkForDeposits() {
//     try {
//         console.log('🔍 Scanning for new transactions to:', targetAddress);
//         const latestBlock = await web3.eth.getBlock('latest');
//         const blockNumber = latestBlock.number;
//         console.log(`📦 Checking block ${blockNumber}`);

//         // Retrieve all transactions from the latest block
//         const transactions = await Promise.all(
//             latestBlock.transactions.map(txHash => web3.eth.getTransaction(txHash))
//         );

//         // Filter for transactions sent to the target address
//         const deposits = transactions.filter(tx => tx.to && tx.to.toLowerCase() === targetAddress);

//         for (const deposit of deposits) {
//             const amount = web3.utils.fromWei(deposit.value, 'ether');
//             console.log(`💰 Deposit detected from ${deposit.from} with amount ${amount} ETH`);
//             // Add your deposit handling logic here
//         }
//     } catch (error) {
//         console.error('❌ Error during deposit check:', error);
//     }
// }

// // Poll for new deposits every 30 seconds (adjust as needed)
// // setInterval(checkForDeposits, 30000);

