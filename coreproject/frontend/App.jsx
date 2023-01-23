import React, {useEffect} from "react"
import { Connect2ICProvider } from "@connect2ic/react"
import "@connect2ic/core/style.css"
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
          [ˈVƆDAO]
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

export default () => (
    <App />
)
