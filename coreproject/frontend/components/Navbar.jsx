import React, { useEffect, useState } from 'react';
import { useCanister, useBalance, useWallet,ConnectButton,ConnectDialog} from "@connect2ic/react"
import {Link} from "react-router-dom"
import {PlusIcon, HomeIcon, LockClosedIcon, UserAddIcon} from '@heroicons/react/solid'
import { Principal } from '@dfinity/principal';
import { getWhitelist } from '../utils';
import PlugConnect from '@psychedelic/plug-connect';

const Navbar = () => {

   async function handleConnectWallet(){
    const result = await window.ic.plug.isConnected();
    console.log("result", result)
    let principal = await window.ic.plug.agent.getPrincipal()
    console.log("principal", principal);
    let principalClean = new Principal(principal._arr);
    console.log("principalClean", principalClean.toString());
    localStorage.setItem("principal", principalClean);
    window.location.reload();
   }

   useEffect(() => {
    async function checkConnection(){
        let whitelist = getWhitelist();
        console.log("whitelist", whitelist)
        const connected = await window.ic.plug.isConnected();
        // if (!connected) {window.ic.plug.requestConnect({ whitelist});}
        if (connected && !window.ic.plug.agent) {
          window.ic.plug.createAgent({ whitelist })
        }
    }
    checkConnection();
   }, []);



  return (
        <>
          <div className="mx-auto max-w-7xl px-2 sm:px-6 lg:px-8">
                <div className='grid grid-cols-12 mt-3 gap-3'>
                    <div className='col-span-3 text-md mt-3 font-bold flex'>
                        <HomeIcon className='h-6 w-6'/>
                        <Link to="/">Home</Link>
                    </div>
                    <div className='col-span-7 mt-5 text-md font-bold flex ml-80'>
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
                        <PlugConnect
                            dark
                            whitelist={["7mmib-yqaaa-aaaap-qa5la-cai","db3eq-6iaaa-aaaah-abz6a-cai","7fpd5-oyaaa-aaaap-qa5kq-cai"]}
                            title="Connect to [ˈVƆDAO]"
                            onConnectCallback={() => {handleConnectWallet()}}
                            className="mb-10"
                        />
                    </div>
                </div>
          </div>
        </>
  )
}
export {Navbar};