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

  let [daoC, setDaoC] = useState({});
  let [mbtC, setMbtC] = useState({});

  const [wallet] = useWallet()

  const [balance, setBalance] = useState(0)
  const [neuron, setNeuron] = useState(0)
  const [neuronState, setNeuronState] = useState()
  const [startDate, setStartDate] = useState(new Date());
  const [votingPower, setVotingPower] = useState(0);
  const [pid, setPid] = useState("");

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
    let amount = document.getElementById("amount").value
    console.log("amount", amount)
    let subAccount = await daoC.getAddress();
    console.log("subAccount", subAccount)
    let princinpalCanister = await daoC.idQuick();
    let transferParameters = {
      to: {
        owner : princinpalCanister,
        subaccount : [subAccount],
      },
      fee: [BigInt(1000000)],
      memo: [],
      from_subaccount: [],
      created_at_time: [],
      amount: amount*100000000,
    }
    const newMbtC = await window?.ic?.plug?.createActor({
      canisterId: "db3eq-6iaaa-aaaah-abz6a-cai",
      interfaceFactory: mbt.idlFactory,
    });
    console.log("newMbtC", newMbtC)
    await newMbtC.icrc1_transfer(transferParameters)
    // console.log("send", send)
    // refreshBalance()
  }

  const refreshBalance = async (principal) => {
      // const principal = await window.ic.plug.agent.getPrincipal();
      let account = {owner : Principal.fromText(principal), subaccount : []}
      const freshMbtBalance = await daoC._getBalance(account)
      console.log("freshMbtBalance", freshMbtBalance)
      setBalance(Number(freshMbtBalance/BigInt(100000000)))
  }
  

  const refreshNeuron = async (principal) => {
    console.log("refresh neuron", principal)
    let account = Principal.fromText(principal)
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

  var daoCanisterId;
  var mbtCanisterId;
  let env = "mainnet"

  const whitelist = [daoCanisterId, mbtCanisterId];

  async function setCannister(){
    // Initialise Agent, expects no return value
    const result = await window.ic.plug.isConnected();
    console.log(`Plug connection is ${result}`);
    // const publicKey = await window.ic.plug.requestConnect();
    // console.log("publicKey", publicKey)
    const newDaoC = await window.ic.plug.createActor({
      canisterId: daoCanisterId,
      interfaceFactory: dao.idlFactory,
    });
    console.log("new daoC", newDaoC)
    daoC = newDaoC;
    setDaoC(newDaoC)
    const newMbtC = await window?.ic?.plug?.createActor({
      canisterId: mbtCanisterId,
      interfaceFactory: mbt.idlFactory,
    });
    mbtC = newMbtC;
    setMbtC(newMbtC)
    let principal = window.ic.plug.sessionManager.sessionData.principalId
    console.log("principal", principal)
    setPid(principal)
    refreshBalance(principal)
    refreshNeuron(principal)
  }

  useEffect(() => {
    if (env==="mainnet"){
      daoCanisterId = "7mmib-yqaaa-aaaap-qa5la-cai"
      mbtCanisterId = "db3eq-6iaaa-aaaah-abz6a-cai"
    } else {
      daoCanisterId = "rkp4c-7iaaa-aaaaa-aaaca-cai"
      mbtCanisterId = "renrk-eyaaa-aaaaa-aaada-cai"
    }
    async function init(){
      await setCannister()
    }
    init()
  }, [])

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
            MBT balance: {balance.toLocaleString()}
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
