import React, {Fragment,useEffect, useState} from "react"
import "@connect2ic/core/style.css"
import * as dao from "../.dfx/local/canisters/dao"
import "./index.css"
import {Navbar} from "./components/Navbar"
import { Principal } from '@dfinity/principal';
import {CubeTransparentIcon, XCircleIcon} from '@heroicons/react/solid'
import { Transition } from '@headlessui/react'
import LoadingGif from './loading.gif'




function Delegate() {

  let [allNeurons, setAllNeurons] = useState([]);
  const [show, setShow] = useState(false)
  const [resultMessage, setResultMessage] = useState("")
  const [loading, setLoading] = useState(false)


  let [daoC, setDaoC] = useState({});

  async function follow(principArr){
    setLoading(true)
    console.log("following", daoC)
    let principal = new Principal(principArr);
    let res = await daoC.follow(principal)
    let inter = Object.keys(res)[0]
    if(inter == "CommonDaoError") {
        setResultMessage("Call result: "+res.CommonDaoError.GenericError.message)
        setShow(true)
        setLoading(false)
    } else {
        setResultMessage("Successfully followed")
        setShow(true)
        setLoading(false)
    }
    console.log("inter", inter)
  };

  useEffect(() => {
    async function getAllNeurons(){
        const newDaoC = await window.ic.plug.createActor({
            canisterId: "7mmib-yqaaa-aaaap-qa5la-cai",
            interfaceFactory: dao.idlFactory,
        });
        let res = await newDaoC.getAllNeurons()
        console.log("all neurons", res)
        setDaoC(newDaoC);
        setAllNeurons(res)
    }
    getAllNeurons()
  },[])

  return (
    <>
    <div className="bg-white">
      <Navbar/>
      <div className="mx-auto max-w-7xl py-16 px-6 sm:py-24 lg:px-8">
        <div className="text-center">
          <p className="mt-1 text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl lg:text-6xl">
          Trust
          </p>
          <p className="mx-auto mt-5 max-w-xl text-xl text-gray-500">
            Follow trusted participant votes
          </p>
          <br/>
          <ul role="list" className="space-y-3 w-3/4 container">
            {allNeurons.map((item, index) => (
                <li key={index} className="overflow-hidden rounded-md bg-white px-6 py-4 shadow">
                Owner {new Principal(item.owner._arr).toString()}
                <br/>
                State {Object.keys(item?.neuronState)[0]}
                <br/>
                Amount Locked {Number(item.amount)/100000000} MBT
                <br/>
                Dissolve Delay {Number(item.dissolveDelay)} nano seconds
                <br/>
                Followed by {Number(item.isFollowedBy.length)} other neurons
                <br/>
                Following&nbsp;
                {(Array.isArray(item.isFollowing) && item.isFollowing.length == 0) ? ("No followers") : (
                    <p>
                    {new Principal(item.isFollowing[0].owner._arr).toString()}
                    </p>
                )}
                <br/>
                <br/>
                {loading ? (
                    <>
                    <img className="h-10 w-10 inline-flex items-center " src={LoadingGif}/>   
                    </>
                ) :(
                    <button
                    type="button"
                    className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-black hover:bg-gray-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                    onClick={(e)=>{e.preventDefault();follow(item.owner._arr)}}
                   >
                   Follow
                   </button>
                )}
                </li>
            ))}
          </ul>
          <br/>
          <br/>
          <br/>
        </div>
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
    </>
  )
}

export default () => (
    <Delegate />
)
