import { useCanister } from "@connect2ic/react"
import React, { useEffect, useState } from "react"

const Proposals = () => {
  /*
  * This how you use canisters throughout your app.
  */
  const [daoC] = useCanister("dao")
  const [daoProposals, setDaoProposals] = useState([])
  const [refreshDone, setRefreshDone] = useState(false)

  const refreshDaoProposals = async () => {
    console.log("getting dao proposals")
    const freshDaoProposals = await daoC.getProposals()
    console.log("freshDaoProposals", freshDaoProposals[0])
    setDaoProposals(freshDaoProposals)
    setRefreshDone(true)
  }

  const handleNewProposal = async (e) => {
    e.preventDefault()
    let propText = document.getElementById("comment").value
    console.log("e.target.form.comment.value", propText)
    console.log("newProposal", propText)
    await daoC.addProposal(propText)
    refreshDaoProposals()
  }

  useEffect(()=>{}, [refreshDone])

  useEffect(() => {
    console.log("dao proposals 0", daoProposals)
    if (!daoProposals) {
      return
    }
    refreshDaoProposals()
  }, [])

  return (
    <div className="">
        <div>
            <br/>
            <br/>
            <br/>
        <label htmlFor="comment" className="block text-sm font-medium text-gray-700">
            Add your proposal
        </label>
        <div className="mt-1">
            <textarea
            rows={4}
            name="comment"
            id="comment"
            className="w-1/3 rounded-md border-solid border-indigo-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
            defaultValue={''}
            />
        </div>
        <button
        type="button"
        className="inline-flex items-center rounded border border-transparent bg-indigo-600 px-2.5 py-1.5 text-xs font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2"
        onClick={handleNewProposal}
        >
        Add Proposal
      </button>
        </div>
        <ul role="list" className="divide-y divide-gray-200">
        {daoProposals.map((item) => (
            <li key={item.newProposal} className="py-4">
                <div className="font-bold">{item.newProposal}</div>
                <div>Votes : {Number(item.numberOfVotes)}</div>
            </li>
        ))}
        </ul>
    </div>
  )
}

export { Proposals }