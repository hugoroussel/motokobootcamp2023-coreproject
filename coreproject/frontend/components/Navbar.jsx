import React, { useEffect, useState } from 'react';
import { useCanister, useBalance, useWallet,ConnectButton,ConnectDialog} from "@connect2ic/react"
import {Link} from "react-router-dom"
import {PlusIcon, HomeIcon} from '@heroicons/react/solid'
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
                <div className='grid grid-cols-12 mt-3 gap-0'>
                    <div className='col-span-3 text-md mt-3 font-bold'>
                        {wallet ? 
                        mbtBalance.toLocaleString() + ' MBT' 
                        : '0 MBT'}
                    </div>
                    <div className='col-span-1'>
                    </div>
                    <div className='col-span-3'>
                    </div>
                    <div className='col-span-1 mt-3 text-md font-bold flex'>
                        <HomeIcon className='h-6 w-6 mx-1 mb-2'/>
                        <Link to="/">Home</Link>
                    </div>
                    <div className='col-span-2 mt-3 text-md font-bold flex'>
                        <PlusIcon className='h-6 w-6'/>
                        <Link to="/new">New proposal</Link>
                    </div>
                    <div className='col-span-2'>
                        <ConnectButton/>
                    </div>
                    <ConnectDialog />
                </div>
          </div>
        </>
  )
}
export {Navbar};