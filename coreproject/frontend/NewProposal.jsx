import React, { useEffect, useState } from "react"
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider,ConnectButton } from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as dao from "../.dfx/local/canisters/dao"
import "./index.css"
import {Navbar} from "./components/Navbar"
import { useCanister } from "@connect2ic/react"


function NewProposal() {

  // const [daoC] = useCanister("dao")

  const [threshold, setThreshold] = useState(0)
  const [minimumVP, setMinimumVP] = useState(0)
  const [quadraticVoting, setQuadraticVoting] = useState(0)

  async function getCurrentParameters() {
    const daoC = await window.ic.plug.createActor({
      canisterId: "7mmib-yqaaa-aaaap-qa5la-cai",
      interfaceFactory: dao.idlFactory,
    });
    let vp = await daoC.getMinimumVotingPower()
    let thresh = await daoC.getThreshold()
    let qc = await daoC.getQuadraticVotingEnabled()
    setThreshold(thresh)
    setMinimumVP(vp)
    setQuadraticVoting(qc)
  }

  useEffect(() => {
    getCurrentParameters()
  }, [])

  async function handleNewProposal(typeOfProposal){
    const daoC = await window.ic.plug.createActor({
      canisterId: "7mmib-yqaaa-aaaap-qa5la-cai",
      interfaceFactory: dao.idlFactory,
    });
    console.log("handleNewProposal", typeOfProposal)
    if(typeOfProposal === "standard"){
      let propText = document.getElementById("comment").value
      let proposalType = {
        "Standard": null,
      }
      console.log("newProposal", propText)
      let prop = await daoC.submitProposal(propText, proposalType)
      console.log("prop", prop)
    } else if(typeOfProposal === "minimum") {
      let newMin = document.getElementById("newMin").value
      if (newMin <= 0 || newMin == minimumVP) {
        console.log("invalid minimum voting power")
        return
      }
      let minObject = {newMinimum: Number(newMin),}
      let proposalType = {
        "MinimumChange": minObject,
      }
      let prop = await daoC.submitProposal("Change Minimum Voting Power to "+newMin, proposalType)
      console.log("prop", prop)
    } else if (typeOfProposal === "threshold") {
      let newThreshold = document.getElementById("threshold").value
      console.log("newThreshold", newThreshold)
      if (newThreshold <= 0 || newThreshold == threshold) {
        console.log("invalid new threshold")
        return
      }
      let thresholdObject = {newThreshold: Number(newThreshold),}
      let proposalType = {
        "ThresholdChange": thresholdObject,
      }
      let prop = await daoC.submitProposal("Change Acceptance/Rejection Threshold to "+newThreshold, proposalType)
      console.log("prop", prop)
    } else if (typeOfProposal === "qc") {
      let propText = quadraticVoting? "Disable Quadratic Voting" : "Enable Quadratic Voting"
      let proposalType = {
        "ToggleQuadraticVoting": null,
      }
      console.log("newProposal", propText)
      let prop = await daoC.submitProposal(propText, proposalType)
      console.log("prop", prop)
    }

  }

  return (
    <div className="bg-white">
      <Navbar/>
      <div className="mx-auto max-w-7xl py-16 px-6 sm:py-24 lg:px-8">
      <div className="text-center">
          <p className="mt-1 text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl lg:text-6xl">
          [ˈVƆDAO]
          </p>
          <p className="mx-auto mt-5 max-w-xl text-xl text-gray-500">
            Liquid Democracy for the Internet Computer
          </p>
      </div>
      <br/>
      <br/>
      <div className="grid grid-cols-2 gap-6">
      <div className="container overflow-hidden rounded-lg bg-white shadow">
          <div className="px-4 py-5 sm:p-6 text-center font-bold">
            <h1 className="text-xl">Standard proposal</h1>
            <div>
            <label htmlFor="comment" className="block text-sm font-medium text-gray-700">
              Add your proposal
            </label>
            <div className="mt-1">
              <textarea
                rows={4}
                name="comment"
                id="comment"
                className="block w-full rounded-md border-gray-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
                defaultValue={''}
              />
            </div>
            <br/>
            <button
                  type="button"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                  onClick={(e)=>{e.preventDefault();handleNewProposal("standard")}}
                >
            Submit
            </button>
            <br/>
          </div>
          </div>
       </div>


       <div className="container overflow-hidden rounded-lg bg-white shadow">
          <div className="px-4 py-5 sm:p-6 text-center font-bold container">
            <h1 className="text-xl">Change Minimum Voting Power</h1>
            <br/>
            <label htmlFor="comment" className="block text-sm font-medium text-gray-700">
              Suggest a new minimum voting power. Current {minimumVP}
            </label>
            <br/>
            <input
            type="number"
            name="amount"
            id="newMin"
            className=""
            placeholder="0"
            aria-describedby="price-currency"/>
            &nbsp;&nbsp;
            <br/>
            <br/>
            <br/>
            <button
                  type="button"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                  onClick={(e)=> {e.preventDefault();handleNewProposal("minimum")}}
                >
            Submit
            </button>
            <br/>
        </div>
      </div>

      <div className="container overflow-hidden rounded-lg bg-white shadow">
        <div className="px-4 py-5 sm:p-6 text-center font-bold container">
          <h1 className="text-xl">Change Acceptance Threshold</h1>
          <br/>
          <label htmlFor="comment" className="block text-sm font-medium text-gray-700">
            Suggest a new acceptance/rejection threshold. Current : {threshold}
          </label>
          <br/>
          <input
          type="number"
          name="amount"
          id="threshold"
          className=""
          placeholder="0.00"
          aria-describedby="price-currency"/>
          <br/>
          <br/>
          <br/>
          <button
                type="button"
                className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                onClick={(e)=> {e.preventDefault();handleNewProposal("threshold")}}
              >
          Submit
          </button>
          
      </div>
      </div>

    <div className="container overflow-hidden rounded-lg bg-white shadow">
          <div className="px-4 py-5 sm:p-6 text-center font-bold container">
            <h1 className="text-xl">Toggle Quadratic Voting</h1>
            <br/>
            <label htmlFor="comment" className="block text-sm font-medium text-gray-700">
              Enable/Disable quadratic voting. Current : {quadraticVoting ? "Enabled" : "Disabled"}
            </label>
            <br/>
            <br/>
            <br/>
            <br/>
            <button
                  type="button"
                  className="inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-full shadow-sm text-white bg-gray-800 hover:bg-gray-900 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-black"
                  onClick={(e)=> {e.preventDefault();handleNewProposal("qc")}}
                >
            Submit
            </button>
            <br/>
        </div>
      </div>

      </div>


        
      </div>
    </div>
  )
}

const client = createClient({
  canisters: {
    dao,
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
    <NewProposal />
  </Connect2ICProvider>
)
