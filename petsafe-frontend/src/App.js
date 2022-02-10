import logo from './logo.svg';
import { useEffect, useState } from 'react';
import { ethers } from 'ethers';
import './App.css';
import petSafeContract from "./contracts/PetSafe.json";

const contractAddress = "0x0dB81d10c1D88626bf77202eBe847FC32038230F"; //TODO Define this
const abi = petSafeContract.abi;

function App() {

  const [currentAccount, setCurrentAccount] = useState(null);

  const checkWalletIsConnected = () => {

    const { ethereum } = window;

    if (!ethereum) {
      console.log("Make sure you have Metamask Installed!");
      return;
    } else {
      console.log("Wallet Exists, Good to Go!");
    }
  }

  const connectWalletHandler = async () => {
    const { ethereum } = window;

    if (!ethereum) {
      alert("Please Install Metamask!");
    }

    try {
      const accounts = await ethereum.request({ method: 'eth_requestAccounts'});
      console.log("Found an Account! Address: ", accounts[0]);
      setCurrentAccount(accounts[0]);
    } catch (err) {
      console.log(err)
    }
   }

  const openPetSafeHandler = async () => {
    try {
      const { ethereum } = window;

      if (ethereum) {
        const provider = new ethers.providers.Web3Provider(ethereum);
        const signer = provider.getSigner();
        const contract = new ethers.Contract(contractAddress, abi, signer);

        console.log("Opening PetSafe!");
        let openTxn = await contract.open({ value: ethers.utils.parseEther("0.001") });
        console.log("Mining...Please Wait");
        await openTxn.wait();

        console.log(`Mined, see transaction: ${openTxn.hash}`);
      } else {
        console.log("Ethereum Object does not Exist!");
      }
    } catch (err) {
      console.log(err);
    }
   }

  const connectWalletButton = () => {
    return (
      <button onClick={connectWalletHandler} className='cta-button connect-wallet-button'>
        Connect Wallet
      </button>
    )
  }

  const openPetSafeButton = () => {
    return (
      <button onClick={openPetSafeHandler} className='cta-button mint-nft-button'>
        Open PetSafe
      </button>
    )
  }

  useEffect(() => {
    checkWalletIsConnected();
  }, [])

  return (
    <div className='main-app'>
      <h1>PetSafe</h1>
      <div>
        {currentAccount ? openPetSafeButton() : connectWalletButton()}
      </div>
    </div>
  )
}

export default App;
