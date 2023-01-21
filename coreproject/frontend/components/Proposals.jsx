import { useCanister } from "@connect2ic/react"
import React, { useEffect, useState } from "react"
import { ArrowDownIcon, ArrowUpIcon } from '@heroicons/react/solid'

const Proposals = () => {
  /*
  * This how you use canisters throughout your app.
  */
  const [daoC] = useCanister("dao")
  const [daoProposals, setDaoProposals] = useState([])
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
    console.log("id upvote", id, upvote)
    await daoC.vote(id, upvote)
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
              <div className="grid grid-cols-5 border-2 border-solid rounded-md p-1 hover:bg-slate-100" key={item.id}>
                <div className="col-span-1">
                  <div>ID : {Number(item.id)}</div>
                </div>
                <div className="col-span-4">
                  <div className="font-bold">{item.proposalText}</div>
                  <div>Votes : {Number(item.numberOfVotes)}</div>
                  <div>Status : {Object.keys(item.status)[0]}</div>   
                </div>
              </div>  
        ))}
        {showAccepted && daoAcceptedProposals.map((item) => (
              <div className="grid grid-cols-5 border-2 border-solid rounded-md p-1 hover:bg-slate-100" key={item.id}>
                <div className="col-span-1">
                  <div>ID : {Number(item.id)}</div>
                </div>
                <div className="col-span-4">
                  <div className="font-bold">{item.proposalText}</div>
                  <div>Votes : {Number(item.numberOfVotes)}</div>
                  <div>Status : {Object.keys(item.status)[0]}</div>   
                </div>
              </div>  
        ))}
        {showOngoing && daoOngoingProposals.map((item) => (
              <div className="grid grid-cols-5 border-2 border-solid rounded-md p-1 hover:bg-slate-100" key={item.id}>
                <div className="col-span-1">
                  <button onClick={(e) => handleVote(e, item.id, true)}>
                    <ArrowUpIcon className="h-6 w-6"/>
                  </button>
                  <button onClick={(e) => handleVote(e, item.id, false)}>
                    <ArrowDownIcon className="h-6 w-6"/>
                  </button>
                  <div>ID : {Number(item.id)}</div>
                </div>
                <div className="col-span-4">
                  <div className="font-bold">{item.proposalText}</div>
                  <div>Votes : {Number(item.numberOfVotes)}</div>
                  <div>Time : {(new Date(Number(item.time/BigInt(1000000000))*1000)).toString().substring(3,24)}</div>
                </div>
              </div>  
        ))}
        </dl>
    </div>
  )
}

export { Proposals }