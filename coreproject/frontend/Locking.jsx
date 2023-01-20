import React, {useEffect} from "react"
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider} from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as dao from "../.dfx/local/canisters/dao"
import * as mbt from "../.dfx/local/canisters/mbt"
import "./index.css"
import {Navbar} from "./components/Navbar"
import { useCanister } from "@connect2ic/react"
import { Principal } from '@dfinity/principal';


function Locking() {

  const [daoC] = useCanister("dao")
  const [mbtC] = useCanister("mbt")
  const handleNewApprove = async (e) => {
    e.preventDefault()
    let expireTimestap = BigInt.asIntN(64, BigInt(Math.floor(Date.now()*1000000+100000000*10)));
    console.log("expireTimestap", expireTimestap)
    const hello = {
        from_subaccount: [],
        spender: Principal.fromText(
            'rkp4c-7iaaa-aaaaa-aaaca-cai'
        ),
        amount: 100000000,
        expires_at: [expireTimestap],
        memo: [],
        fee:[],
        created_at_time: [],
    }
    console.log("objectCall", hello)
    let res = await mbtC.icrc2_approve(hello);
    console.log("res approve", res)
    // refreshDaoProposals()
  }

  const handleNewLock = async (e) => {
    console.log("handleNewLock")
    e.preventDefault()
    let subAccount = await daoC.getAddress();
    console.log("subAccount", subAccount)
    let princinpalCanister = await daoC.idQuick();
    let transferParameters = {
      from_subaccount: [],
      to: {
        owner : princinpalCanister,
        subaccount : [subAccount],
      },
      amount: 100000000,
      fee: [],
      memo: [],
      created_at_time: [],
    }
    console.log("transferParameters", transferParameters)
    let send = await mbtC.icrc1_transfer(transferParameters)
    console.log("send", send)
  }

  const handleUnlock = async (e) => {
    e.preventDefault()
    console.log("handleUnlock")
    let send = await daoC.unlock()
    console.log("send", send)
  }


  const balance = async (e) => {
    e.preventDefault()
    console.log("handleUnlock")
    let princinpalCanister = await daoC.idQuick();
    let subAccount = await daoC.getAddress();
    let account = {
      owner: princinpalCanister,
      subaccount: [subAccount],
    }
    let balance = await mbtC.icrc1_balance_of(account)
    console.log("balance", balance)
  }

  const handleCreateNeuron = async (e) => {
    e.preventDefault()
    console.log("handle get time")
    let time = await daoC.createNeuron(100000000,0);
  }

  return (
    <div className="bg-white">
      <Navbar/>
      <div className="mx-auto max-w-7xl py-16 px-6 sm:py-24 lg:px-8">
        <div className="text-center">
          <p className="mt-1 text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl lg:text-6xl">
            Leverage
          </p>
          <p className="mx-auto mt-5 max-w-xl text-xl text-gray-500">
            Leverage time for more influence.
          </p>
          <br/>
          <br/>
          <br/>

          <button
          type="button"
          className="inline-flex items-center rounded border border-transparent bg-indigo-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          onClick={handleNewApprove}
          >
          Approve
          </button>
          &nbsp;&nbsp;&nbsp;&nbsp;
          <button
          type="button"
          className="inline-flex items-center rounded border border-transparent bg-indigo-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          onClick={handleNewLock}
          >
          Lock
          </button>
          &nbsp;&nbsp;&nbsp;&nbsp;
          <button
          type="button"
          className="inline-flex items-center rounded border border-transparent bg-indigo-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          onClick={handleUnlock}
          >
          UnLock
          </button>
          &nbsp;&nbsp;&nbsp;&nbsp;
          <button
          type="button"
          className="inline-flex items-center rounded border border-transparent bg-indigo-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          onClick={balance}
          >
          Balance
          </button>
          &nbsp;&nbsp;&nbsp;&nbsp;
          <button
          type="button"
          className="inline-flex items-center rounded border border-transparent bg-indigo-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
          onClick={handleCreateNeuron}
          >
          Create Neuron
          </button>
        </div>
      </div>
    </div>
  )
}

const client = createClient({
  canisters: {
    dao,
    mbt
  },
  providers: defaultProviders,
  globalProviderConfig: {
    /*
     * Disables dev mode in production
     * Should be enabled when using local canisters
     */
    dev: import.meta.env.DEV,
  },
})


export default () => (
  <Connect2ICProvider client={client}>
    <Locking />
  </Connect2ICProvider>
)
