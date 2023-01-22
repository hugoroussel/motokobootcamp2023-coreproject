import { useCanister } from "@connect2ic/react"
import React, { Fragment, useEffect, useState } from "react"
import { ArrowDownIcon, ArrowUpIcon, XCircleIcon, CubeTransparentIcon} from '@heroicons/react/solid'
import * as dao from "../../.dfx/local/canisters/dao"
import { Transition } from '@headlessui/react'
import LoadingGif from '../loading.gif'

const Proposals = () => {
  /*
  * This how you use canisters throughout your app.
  */
  // const [daoC] = useCanister("dao")
  const [daoProposals, setDaoProposals] = useState([])
  const [show, setShow] = useState(false)
  const [loading, setLoading] = useState(false)
  const [resultMessage, setResultMessage] = useState("")
  const [daoOngoingProposals, setDaoOngoingProposals] = useState([])
  const [daoRejectedProposals, setDaoRejectedProposals] = useState([])
  const [daoAcceptedProposals, setDaoAcceptedProposals] = useState([])
  const [refreshDone, setRefreshDone] = useState(false)

  const [showRejected, setShowRejected] = useState(false);
  const [showAccepted, setShowAccepted] = useState(false);
  const [showOngoing, setShowOngoing] = useState(true);

  function toggleModal(showText){
    if(showText === "rejected"){
      setShowRejected(true)
      setShowAccepted(false)
      setShowOngoing(false)
    } else if(showText === "accepted"){
      setShowRejected(false)
      setShowAccepted(true)
      setShowOngoing(false)
    }
    else if(showText === "ongoing"){
      setShowRejected(false)
      setShowAccepted(false)
      setShowOngoing(true)
    }
  }

  const refreshDaoProposals = async () => {
    const daoC = await window.ic.plug.createActor({
      canisterId: "7mmib-yqaaa-aaaap-qa5la-cai",
      interfaceFactory: dao.idlFactory,
    });
    const freshDaoProposals = await daoC.getAllProposals()
    console.log("getting dao proposals", freshDaoProposals)
    let freshA = []
    let freshR = []
    let freshO = []
    for(let i = 0; i < freshDaoProposals.length; i++) {
      if(Object.keys(freshDaoProposals[i].status)[0] === "OnGoing"){
        freshO.push(freshDaoProposals[i])
      } else if(Object.keys(freshDaoProposals[i].status)[0] === "Rejected"){
        freshR.push(freshDaoProposals[i])
      }
      else if(Object.keys(freshDaoProposals[i].status)[0] === "Accepted"){
        freshA.push(freshDaoProposals[i])
      }
    }
    setDaoOngoingProposals(freshO)
    setDaoRejectedProposals(freshR)
    setDaoAcceptedProposals(freshA)
    setDaoProposals(freshDaoProposals)
    console.log("freshDaoProposals", freshDaoProposals)
    setRefreshDone(true)
  }

  async function handleVote(e,id,upvote) {
    e.preventDefault()
    setLoading(true)
    const daoC = await window.ic.plug.createActor({
      canisterId: "7mmib-yqaaa-aaaap-qa5la-cai",
      interfaceFactory: dao.idlFactory,
    });
    console.log("id upvote", id, upvote)
    try {
      let res = await daoC.vote(id, upvote)
      console.log("res", res)
      let inter = Object.keys(res)[0]
      if(inter == "CommonDaoError") {
        setResultMessage("Call result: "+res.CommonDaoError.GenericError.message)
        setShow(true)
        setLoading(false)
      } else {
        setLoading(false)
        setResultMessage("Vote successful")
        setShow(true)
      }
    } catch (error) {
      console.log("error", error)
      setLoading(false)
      setResultMessage("Vote failed")
      setShow(true)
    }
    
    refreshDaoProposals()
  }

  useEffect(()=>{}, [refreshDone])
  useEffect(()=>{}, [daoRejectedProposals])
  useEffect(()=>{}, [refreshDone])


  
  useEffect(() => {
    console.log("dao proposals 0", daoProposals)
    if (!daoProposals) {
      return
    }
    refreshDaoProposals()
  }, [])
  

  return (
    <div className="container w-3/4">
        <div className="flex">
        <h3 className="text-lg font-medium leading-6 text-gray-900">
          <button
            type="button"
            className="inline-flex items-center px-3 py-1.5 border border-transparent text-2xl rounded-full text-gray-700 hover:text-gray-900"
            onClick={(e)=>{e.preventDefault();toggleModal("ongoing")}}
          >
          Ongoing
        </button>
        </h3>
        &nbsp;
        &nbsp;
        &nbsp;
        <h3 className="text-lg font-medium leading-6 text-gray-900">
        <button
            type="button"
            className="inline-flex items-center px-3 py-1.5 border border-transparent text-2xl font-semibold rounded-full text-gray-700 hover:text-gray-900"
            onClick={(e)=>{e.preventDefault();toggleModal("accepted")}}
          >
          Accepted
        </button>
        </h3>
        &nbsp;
        &nbsp;
        &nbsp;
        <h3 className="text-lg font-medium leading-6 text-gray-900">
          <button
              type="button"
              className="inline-flex items-center px-3 py-1.5 border border-transparent text-2xl font-extralight rounded-full text-gray-700 hover:text-gray-900"
              onClick={(e)=>{e.preventDefault();toggleModal("rejected")}}
            >
            Rejected
          </button>
        </h3>
        </div>
        <dl className="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-3">
        {showRejected && 
        daoRejectedProposals.map((item) => (
              <div className="grid grid-cols-3 border-2 border-solid rounded-md p-1 hover:bg-slate-100" key={item.id}>
                <div className="col-span-1">
                  <div>ID : {Number(item.id)}</div>
                </div>
                <div className="col-span-4">
                  <div className="font-bold">{item.proposalText.substring(0,40)}</div>
                  <div>Votes : {Number(item.numberOfVotes)}</div>
                  <div>Status : {Object.keys(item.status)[0]}</div>   
                </div>
              </div>  
        ))}
        {showAccepted && daoAcceptedProposals.map((item) => (
              <div className="grid grid-cols-3 border-2 border-solid rounded-md p-1 hover:bg-slate-100" key={item.id}>
                <div className="col-span-1">
                  <div>ID : {Number(item.id)}</div>
                </div>
                <div className="col-span-4">
                  <div className="font-bold">{item.proposalText.substring(0,40)}</div>
                  <div>Votes : {Number(item.numberOfVotes)}</div>
                  <div>Status : {Object.keys(item.status)[0]}</div>   
                </div>
              </div>  
        ))}
        {showOngoing && daoOngoingProposals.map((item) => (
              <div className="grid grid-cols-3 border-2 border-solid rounded-md p-1 hover:bg-slate-100" key={item.id}>
                <div className="col-span-1">
                  {loading? (
                    <img className="h-10 w-10 inline-flex items-center " src={LoadingGif}/>   
                  ) : (
                    <>
                  <button onClick={(e) => handleVote(e, item.id, true)}>
                    <ArrowUpIcon className="h-6 w-6"/>
                  </button>
                  <button onClick={(e) => handleVote(e, item.id, false)}>
                    <ArrowDownIcon className="h-6 w-6"/>
                  </button>
                  </>
                  )}
                  <div>ID : {Number(item.id)}</div>
                </div>
                <div className="col-span-4">
                  <div className="font-bold">{item.proposalText.substring(0,35)}</div>
                  <div>Votes : {Number(item.numberOfVotes)}</div>
                  <div>Time : {(new Date(Number(item.time/BigInt(1000000000))*1000)).toString().substring(3,24)}</div>
                </div>
              </div>  
        ))}
        </dl>
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

export { Proposals }