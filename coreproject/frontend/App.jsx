import React from "react"
import { createClient } from "@connect2ic/core"
import { defaultProviders } from "@connect2ic/core/providers"
import { Connect2ICProvider } from "@connect2ic/react"
import "@connect2ic/core/style.css"
import * as dao from "../.dfx/local/canisters/dao"
import {DaoName} from "./components/DaoName"
import "./index.css"

function App() {

  return (
    <div className="App">

      <header className="App-header">
        <p className="examples-title">
          <DaoName/>
        </p>
      </header>


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
