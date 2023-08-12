async function connect() {
   if (window.ethereum) {
      await window.ethereum.request({ method: "eth_requestAccounts" });
      window.web3 = new Web3(window.ethereum);
      const account = web3.eth.accounts;
      //Get the current MetaMask selected/active wallet
      const walletAddress = account.givenProvider.selectedAddress;
      console.log(`Wallet: ${walletAddress}`);

   } else {
      console.log("No wallet");
   }
}
let web3;

async function connectMetaMask() {
   // Check if MetaMask is installed
   if (typeof window.ethereum !== 'undefined') {
      web3 = new Web3(window.ethereum);
      try {
         // Request account access
         await window.ethereum.enable();

         // Add Polygon Network
         await window.ethereum.request({
            method: 'wallet_addEthereumChain',
            params: [{
               chainId: '80001',
               chainName: 'Mumbai Testnet',
               nativeCurrency: {
                  name: 'MATIC',
                  symbol: 'MATIC',
                  decimals: 18
               },
               rpcUrls: ['https://polygon-mumbai.g.alchemy.com/v2/your-api-key'],
               blockExplorerUrls: ['https://mumbai.polygonscan.com/']
            }]
         });

         // Set up the transaction details
         const tx = {
            from: (await web3.eth.getAccounts())[0],
            to: '0x123abc',  // contract address
            value: web3.utils.toWei('1', 'ether'),
            gas: 21000,
            gasPrice: await web3.eth.getGasPrice()
         };

         // Send the transaction (MetaMask will show a popup for the user to sign)
         web3.eth.sendTransaction(tx)
            .on('transactionHash', hash => {
               console.log('Transaction Hash:', hash);
            })
            .on('receipt', receipt => {
               console.log('Receipt:', receipt);
            })
            .on('error', error => {
               console.error('Error sending transaction:', error);
            });

      } catch (error) {
         console.error('User denied account access or error occurred:', error);
      }
   } else {
      console.log('MetaMask is not installed.');
   }
}