import React from "react"
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider,ConnectButton } from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as dao from "../.dfx/local/canisters/dao"
import {DaoName} from "./components/DaoName"
import {Proposals} from "./components/Proposals"
import "./index.css"
import {Navbar} from "./components/Navbar"


function App() {
  return (
    <div className="bg-white">
      <Navbar/>
      <div className="mx-auto max-w-7xl py-16 px-6 sm:py-24 lg:px-8">
        <div className="text-center">
          <p className="mt-1 text-4xl font-bold tracking-tight text-gray-900 sm:text-5xl lg:text-6xl">
          [ˈVƆDA]
          </p>
          <p className="mx-auto mt-5 max-w-xl text-md text-gray-500">
            water in slavic
          </p>
          <p className="mx-auto mt-5 max-w-xl text-xl text-gray-500">
            Liquid Democracy for the Internet Computer
          </p>
          <br/>
          <br/>
          <br/>
          <Proposals/>
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
    <App />
  </Connect2ICProvider>
)
