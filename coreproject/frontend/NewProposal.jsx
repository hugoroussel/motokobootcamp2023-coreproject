import React from "react"
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider,ConnectButton } from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as dao from "../.dfx/local/canisters/dao"
import "./index.css"
import {Navbar} from "./components/Navbar"
import { useCanister } from "@connect2ic/react"


function NewProposal() {

  const [daoC] = useCanister("dao")

  const handleNewProposal = async (e) => {
    e.preventDefault()
    let propText = document.getElementById("comment").value
    console.log("e.target.form.comment.value", propText)
    console.log("newProposal", propText)
    await daoC.submit_proposal(propText)
    refreshDaoProposals()
  }
  return (
    <div className="bg-white">
      <Navbar/>
      <div className="mx-auto max-w-7xl py-16 px-6 sm:py-24 lg:px-8">
        <div className="text-center">
          <p className="mt-1 text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl lg:text-6xl">
            Participate
          </p>
          <p className="mx-auto mt-5 max-w-xl text-xl text-gray-500">
            Add your proposal to the DAO.
          </p>
          <br/>
          <br/>
          <br/>
          <label htmlFor="comment" className="block text-sm font-medium text-gray-700">
            Enter your proposal below
          </label>
          <div className="mt-1">
              <textarea
              rows={4}
              name="comment"
              id="comment"
              className="w-1/3 rounded-md border-solid border-2 border-indigo-300 shadow-sm focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm"
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
