import React, {useEffect, useState} from "react"
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider, useWallet} from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as dao from "../.dfx/local/canisters/dao"
import * as mbt from "../.dfx/local/canisters/mbt"
import "./index.css"
import {Navbar} from "./components/Navbar"
import { useCanister } from "@connect2ic/react"
import { Principal } from '@dfinity/principal';
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import { LightningBoltIcon } from '@heroicons/react/solid'




function Locking() {

  const [daoC] = useCanister("dao")
  const [mbtC] = useCanister("mbt")

  const [wallet] = useWallet()

  const [balance, setBalance] = useState(0)
  const [neuron, setNeuron] = useState(0)
  const [neuronState, setNeuronState] = useState()
  const [startDate, setStartDate] = useState(new Date());
  const [votingPower, setVotingPower] = useState(0);

  const handleDissolve = async (e) => {
    e.preventDefault()
    let res = await daoC.dissolveNeuron()
    console.log("res", res)
  }

  const handleNewCreateNeuron = async (e) => {
    let amount = document.getElementById("amount").value
    let res = await daoC.createNeuron(amount*100000000, 1)
    console.log("res", res)
    refreshBalance()
  }

  const handleNewTransfer = async (e) => {
    e.preventDefault()
    console.log("handle new transfer")
    let amount = document.getElementById("amount").value
    console.log("amount", amount)
    let subAccount = await daoC.getAddress();
    console.log("subAccount", subAccount)
    let princinpalCanister = await daoC.idQuick();
    let transferParameters = {
      from_subaccount: [],
      to: {
        owner : princinpalCanister,
        subaccount : [subAccount],
      },
      amount: amount*100000000,
      fee: [],
      memo: [],
      created_at_time: [],
    }
    console.log("transferParameters", transferParameters)
    let send = await mbtC.icrc1_transfer(transferParameters)
    console.log("send", send)
    refreshBalance()
  }

  const refreshBalance = async () => {
    if (wallet?.principal){
      let account = {owner : Principal.fromText(wallet.principal), subaccount : []}
      const freshMbtBalance = await daoC._getBalance(account)
      console.log("freshMbtBalance", freshMbtBalance)
      setBalance(Number(freshMbtBalance/BigInt(100000000)))
    }
  }

  const refreshNeuron = async () => {
    if (wallet?.principal){
      let account = Principal.fromText(wallet.principal)
      const freshNeuron = await daoC.getNeuron(account)
      setNeuron(freshNeuron)
      if(!(Array.isArray(freshNeuron) && freshNeuron.length === 0)){
        setNeuron(freshNeuron[0])
        let ns = Object.keys(freshNeuron[0]?.neuronState)[0]
        if(ns==="Dissolved"){
          setNeuron([])
        }
        setNeuronState(ns)
        console.log("neur", freshNeuron[0])
        let res = await daoC.getNeuronVotingPower(freshNeuron[0])
        console.log("voting power", res)
        setVotingPower(res)
      }
    }
  }

  useEffect(() => {
    refreshBalance()
    refreshNeuron()
  }, [wallet])

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
          <p className="mx-auto mt-5 max-w-xl text-xl font-bold">
            MBT balance: {balance}
          </p>
          <br/>
          {Array.isArray(neuron) && neuron.length === 0 ?
           (
            <div className="container overflow-hidden rounded-lg bg-white shadow w-1/2">
              <div className="px-4 py-5 sm:p-6 text-xl font-bold">
                Lock MBT now to create a neuron.
              </div>
              <div>
                <label htmlFor="price" className="block text-sm font-medium text-gray-700">
                  Amount of MBTs to Lock
                </label>
                <div className="relative mt-1 rounded-md shadow-sm w-1/3 container">
                  <input
                    type="number"
                    name="amount"
                    id="amount"
                    className="block w-full rounded-md border-gray-300 pl-7 pr-12 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                    placeholder="0.00"
                    aria-describedby="price-currency"
                  />
                  <div className="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-3">
                    <span className="text-gray-500 sm:text-sm" id="price-currency">
                      MBT
                    </span>
                  </div>
                </div>
                <br/>
                <label htmlFor="price" className="block text-sm font-medium text-gray-700">
                  Choose a dissolve delay <br/>(chosen date - today's date = delay)
                </label>
                <DatePicker selected={startDate} onChange={(date) => setStartDate(date)} />
                <br/>
                <br/>
                <button
                  type="button"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
                  onClick={handleNewTransfer}
                >
                Deposit
                </button>
                &nbsp;&nbsp;&nbsp;&nbsp;
                <button
                  type="button"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                  onClick={handleNewCreateNeuron}
                >
                Lock
                </button>
                <br/>
                <br/>
              </div>
            </div>
           ) :
           (
            <div className="container overflow-hidden rounded-lg bg-white shadow w-1/2">
              <div className="px-4 py-5 sm:p-6 text-xl font-bold">
              <LightningBoltIcon className="h-12 w-12 text-center container"/>
              <br/>
               Neuron State {neuronState}
              </div>
              <div className="px-4 py-5 sm:p-6 text-xl font-bold">
                Neuron balance {Number(neuron?.amount)/100000000}
              </div>
              <div className="px-4 py-5 sm:p-6 text-xl font-bold">
                Neuron Voting Power {votingPower/100000000}
              </div>
              <button
                  type="button"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                  onClick={handleDissolve}
                >
                Dissolve
              </button>
              <br/>
              <br/>
            </div>
           )}
          <br/>
          <br/>
          <br/>
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
