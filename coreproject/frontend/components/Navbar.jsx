import React, { useEffect, useState } from 'react';
import { useCanister, useBalance, useWallet,ConnectButton,ConnectDialog} from "@connect2ic/react"

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
            setMbtBalance(freshMbtBalance)
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
                <div className='grid grid-cols-12 mt-3'>
                    <div className='col-span-3 text-md mt-3 font-bold'>
                        {wallet ? 
                        mbtBalance + ' MBT' 
                        : '0 MBT'}
                    </div>
                    <div className='col-span-1'>
                    </div>
                    <div className='col-span-4'>
                    </div>
                    <div className='col-span-2 mt-3 text-md font-bold'>
                        New proposal
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