import React, {Fragment, useEffect, useState} from "react"
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider, useWallet} from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as dao from "../.dfx/local/canisters/dao"
import * as mbt from "../.dfx/local/canisters/mbt"
import "./index.css"
import {Navbar} from "./components/Navbar"
import { Principal } from '@dfinity/principal';
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import { LightningBoltIcon,CubeTransparentIcon, XCircleIcon} from '@heroicons/react/solid'
import LoadingGif from './loading.gif'
import { Transition } from '@headlessui/react'




function Locking() {

  let [daoC, setDaoC] = useState();
  let [mbtC, setMbtC] = useState();
  const [balance, setBalance] = useState(0)
  const [neuron, setNeuron] = useState(0)
  const [neuronState, setNeuronState] = useState()
  const [startDate, setStartDate] = useState(new Date());
  const [votingPower, setVotingPower] = useState(0);
  const [pid, setPid] = useState("");
  const [loading, setLoading] = useState(false);
  const [show, setShow] = useState(false)
  const [loadingButton, setLoadingButton] = useState(false)
  const [resultMessage, setResultMessage] = useState("result message")
  const [isFollowing, setIsFollowing] = useState("")

  const handleDissolve = async (e) => {
    e.preventDefault()
    setLoadingButton(true)
    let res = await daoC.dissolveNeuron()
    console.log("res", res)
    setLoadingButton(false)
    setResultMessage("Neuron dissolved")
    setShow(true)
  }

  const handleNewCreateNeuron = async (e) => {
    setLoadingButton(true)
    let amount = document.getElementById("amount").value
    let res = await daoC.createNeuron(amount*100000000, 1)
    console.log("res", res)
    setLoadingButton(false)
    setResultMessage("Neuron created")
    setShow(true)
    refreshNeuron()
  }

  const handleNewTransfer = async () => {
    setLoadingButton(true)
    let amount = document.getElementById("amount").value
    console.log("amount", amount)
    let subAccount = await daoC.getAddress();
    console.log("subAccount", subAccount)
    // can shave 2 seconds off by hardcoding this
    let princinpalCanister = Principal.fromText("7mmib-yqaaa-aaaap-qa5la-cai")
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
    setMbtC(newMbtC);
    console.log("newMbtC", newMbtC)
    try {
      // there is a bug here.. the transfer is successful but it returns an error "Hash not found"
      let res = await newMbtC.icrc1_transfer(transferParameters)
    } catch(e){
      setLoadingButton(false)
      setShow(true)
      setResultMessage("Transfer successful. Lock now to create your neuron.")
      refreshBalance()
    }
  }

  const refreshBalance = async () => {
      let newDaoC = await window.ic.plug.createActor({
        canisterId: "7mmib-yqaaa-aaaap-qa5la-cai",
        interfaceFactory: dao.idlFactory,
      });
      setDaoC(newDaoC)
      let principal = localStorage.getItem("principal")
      let account = {owner : Principal.fromText(principal), subaccount : []}
      const freshMbtBalance = await newDaoC._getBalance(account)
      setBalance(Number(freshMbtBalance/BigInt(100000000)))
      setLoading(false)
  }
  
  const refreshNeuron = async () => {
    console.log("refreshing neuron")
    let principal = localStorage.getItem("principal")
    let account = Principal.fromText(principal)
    let newDaoC = await window.ic.plug.createActor({
      canisterId: "7mmib-yqaaa-aaaap-qa5la-cai",
      interfaceFactory: dao.idlFactory,
    });
    console.log("new daoC", newDaoC)
    const freshNeuron = await newDaoC.getNeuron(account)
    console.log("freshNeuron", freshNeuron)
    setNeuron(freshNeuron)
    if(!(Array.isArray(freshNeuron) && freshNeuron.length === 0)){
      setNeuron(freshNeuron[0])
      if(Array.isArray(freshNeuron[0].isFollowing) && freshNeuron[0].isFollowing.length == 0){
        setIsFollowing("Not following any neuron")
      } else {
        let p = new Principal(freshNeuron[0].isFollowing[0].owner._arr).toString()
        setIsFollowing("Following Neuron "+ p)
      }
      let ns = Object.keys(freshNeuron[0]?.neuronState)[0]
      if(ns==="Dissolved"){
        setNeuron([])
      }
      setNeuronState(ns)
      setLoading(false)
      let res = await newDaoC.getNeuronTotalVotingPower(freshNeuron[0])
      setVotingPower(res)
    }
  }

  async function handleUnfollow(){
    setLoadingButton(true)
    let p = new Principal(neuron.isFollowing[0].owner._arr)
    try {let res = await daoC.unfollow(p)
      console.log("res", res)
      setIsFollowing("Not following any neuron")
      setLoadingButton(false)
      setResultMessage("Unfollowed")
      setShow(true)}
    catch(e){
      setLoadingButton(false)
      setResultMessage("Error")
      setShow(true)
    }
    
  }

  useEffect(() => {
    refreshBalance()
    refreshNeuron()
    setLoading(true)
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
            Create a neuron to vote and create proposal.
          </p>
          <p className="mx-auto max-w-xl text-xl text-gray-500">
            Lock longer to leverage time.
          </p>
          {loading ? (
            <>
            <br/>
            <br/>
            <p className="mx-auto max-w-xl text-xl text-gray-800">
              Loading be patient... <img src={LoadingGif} className="container h-12 w-12 mt-12"/>
            </p>
            </>
          ) : (
          <>
          <p className="mx-auto mt-5 max-w-xl text-xl font-bold">
            {balance.toLocaleString()} $MBT
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
                {loadingButton ? (
                  <img className="h-10 w-10 inline-flex items-center " src={LoadingGif}/>   
                ) : (
                  <>
                  <button
                  type="button"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                  onClick={(e)=>{e.preventDefault();handleNewTransfer()}}
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
                  </>
                )}
                
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
              <div className="px-4 py-5 sm:p-6 text-xl font-bold">
                {isFollowing}
              </div>
              
              {loadingButton ? (
                <img className="h-10 w-10 inline-flex items-center " src={LoadingGif}/>   
              ) : (
                <>
                <button
                type="button"
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                onClick={handleDissolve}
                > 
                Dissolve
                </button>
                &nbsp;&nbsp;
                {isFollowing === "Not following any neuron" ? ("") : (
                  <button
                  type="button"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                  onClick={(e)=>{e.preventDefault();handleUnfollow()}}
                  > 
                  Unfollow
                  </button>
                )}
                
                </>
              )}
              <br/>
              <br/>
            </div>
           )}
          </>
          )}
          <br/>
          <br/>
          <br/>
        </div>
      </div>
      {/* Global notification live region, render this permanently at the end of the document */}
      <div
          aria-live="assertive"
          className="pointer-events-none fixed inset-0 flex items-end px-4 py-6 sm:items-start sm:p-6"
        >
          <div className="flex w-full flex-col items-center space-y-4 sm:items-end">
            {/* Notification panel, dynamically insert this into the live region when it needs to be displayed */}
            <Transition
              show={show}
              as={Fragment}
              enter="transform ease-out duration-300 transition"
              enterFrom="translate-y-2 opacity-0 sm:translate-y-0 sm:translate-x-2"
              enterTo="translate-y-0 opacity-100 sm:translate-x-0"
              leave="transition ease-in duration-100"
              leaveFrom="opacity-100"
              leaveTo="opacity-0"
            >
              <div className="pointer-events-auto w-full max-w-sm overflow-hidden rounded-lg bg-white shadow-lg ring-1 ring-black ring-opacity-5">
                <div className="p-4">
                  <div className="flex items-start">
                  <div className="flex-shrink-0">
                    <CubeTransparentIcon className="h-10 w-10 text-black" aria-hidden="true" />
                  </div>
                    <div className="ml-3 w-0 flex-1 pt-0.5">
                      <p className="text-sm font-medium text-gray-900">New Notification</p>
                      <p className="mt-1 text-sm text-gray-500">{resultMessage}</p>
                    </div>
                    <div className="ml-4 flex flex-shrink-0">
                      <button
                        type="button"
                        className="inline-flex rounded-md bg-white text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-black focus:ring-offset-2"
                        onClick={() => {
                          setShow(false)
                        }}
                      >
                        <span className="sr-only">Close</span>
                        <XCircleIcon className="h-5 w-5" aria-hidden="true" />
                      </button>
                    </div>
                  </div>
                </div>
              </div>
            </Transition>
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
