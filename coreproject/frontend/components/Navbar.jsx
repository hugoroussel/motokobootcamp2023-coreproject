import React, { useEffect, useState } from 'react';
import { useCanister, useBalance, useWallet,ConnectButton,ConnectDialog} from "@connect2ic/react"
import {Link} from "react-router-dom"
import {PlusIcon, HomeIcon, LockClosedIcon} from '@heroicons/react/solid'
import { HttpAgent } from '@dfinity/agent'

const Navbar = () => {

    const [wallet] = useWallet()
    const [assets] = useBalance()

    const [daoC] = useCanister("dao")
    const [mbtBalance, setMbtBalance] = useState(0)

    const refreshBalance = async () => {
        console.log("wallet", wallet)
        if (wallet?.principal){
            console.log("refreshing balance of", wallet.principal)
            const freshMbtBalance = await daoC._getBalance(wallet.principal)
            console.log("freshMbtBalance", freshMbtBalance)
            setMbtBalance(Number(freshMbtBalance))
        } else {
            console.log("no wallet")
        }
    }

    useEffect(() => {
        console.log("hello navbar")
        refreshBalance()
    }, [wallet])
    
  return (
        <>
          <div className="mx-auto max-w-7xl px-2 sm:px-6 lg:px-8">
                <div className='grid grid-cols-12 mt-3 gap-3'>
                    <div className='col-span-3 text-md mt-3 font-bold'>
                        {wallet ? 
                        mbtBalance.toLocaleString() + ' MBT' 
                        : '0 MBT'}
                    </div>
                    <div className='col-span-7 mt-3 text-md font-bold flex'>
                        <HomeIcon className='h-6 w-6 ml-96'/>
                        <Link to="/">Home</Link>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <PlusIcon className='h-6 w-6'/>
                        <Link to="/new">New proposal</Link>
                        &nbsp;&nbsp;&nbsp;&nbsp;
                        <LockClosedIcon className='h-6 w-6'/>
                        <Link to="/lock">Locking</Link>
                    </div>
                    <div className='col-span-2'>
                        <ConnectButton
                        onConnect={() => {window.ic?.plug.sessionManager.sessionData?.agent.fetchRootKey();console.log("connected")}}
                        />
                    </div>
                    <ConnectDialog />
                </div>
          </div>
        </>
  )
}
export {Navbar};