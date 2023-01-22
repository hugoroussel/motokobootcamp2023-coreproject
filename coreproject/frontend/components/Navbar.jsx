import React, { useEffect, useState } from 'react';
import { useCanister, useBalance, useWallet,ConnectButton,ConnectDialog} from "@connect2ic/react"
import {Link} from "react-router-dom"
import {PlusIcon, HomeIcon, LockClosedIcon, UserAddIcon} from '@heroicons/react/solid'
import { Principal } from '@dfinity/principal';
import { getWhitelist } from '../utils';

const Navbar = () => {

   let [connected, setConnected] = useState(false);

   async function handleConnectWallet(){
    if(connected){
        setConnected(false);
        localStorage.setItem("principal", "");
        return;
    } else {
        let principal = window.ic.plug.sessionManager.sessionData.principalId
        console.log("principal", principal);
        localStorage.setItem("principal", principal);
    }
    console.log(getWhitelist());
    let whitelist = getWhitelist();
    try {
        const publicKey = await window.ic.plug.requestConnect({
          host : "https://mainnet.dfinity.network",
          whitelist,
          timeout: 50000
        });
        setConnected(true);
    } catch (e) {
        console.log(e);
    }
   }

   useEffect(() => {
    async function checkPlugIsConnected() {
        const result = await window.ic.plug.isConnected();
        if(result){
            let principal = window.ic.plug.sessionManager.sessionData.principalId
            console.log("principal", principal);
            localStorage.setItem("principal", principal);
            setConnected(true);
        } else {
            setConnected(false);
        }
    }
    checkPlugIsConnected();
   }, []);



  return (
        <>
          <div className="mx-auto max-w-7xl px-2 sm:px-6 lg:px-8">
                <div className='grid grid-cols-12 mt-3 gap-3'>
                    <div className='col-span-3 text-md mt-3 font-bold flex'>
                        <HomeIcon className='h-6 w-6'/>
                        <Link to="/">Home</Link>
                    </div>
                    <div className='col-span-7 mt-3 text-md font-bold flex ml-80'>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <PlusIcon className='h-6 w-6'/>
                        <Link to="/new">Proposal</Link>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <LockClosedIcon className='h-6 w-6'/>
                        <Link to="/lock">Lock</Link>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <UserAddIcon className='h-6 w-6 mr-1'/>
                        <Link to="/delegate">Delegate</Link>
                    </div>
                    <div className='col-span-2'>
                        <button 
                        type="button"
                        className="inline-flex items-center rounded-full border border-transparent bg-black px-6 py-2 text-xl font-medium text-white shadow-sm hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2"
                        onClick={(e)=>{e.preventDefault();handleConnectWallet()}}
                        >
                        {connected ? "Disconnect" : "Connect"}
                        </button>
                    </div>
                </div>
          </div>
        </>
  )
}
export {Navbar};