import { useCanister } from "@connect2ic/react"
import React, { useEffect, useState } from "react"

const DaoName = () => {
  /*
  * This how you use canisters throughout your app.
  */
  const [daoC] = useCanister("dao")
  const [daoName, setDaoName] = useState("no name")

  const refreshDaoName = async () => {
    const freshDaoName = await daoC.getDaoName()
    setDaoName(freshDaoName)
  }

  useEffect(() => {
    if (!daoName) {
      return
    }
    refreshDaoName()
  }, [daoName])

  return (
    <div className="example">
      <p style={{ fontSize: "2.5em" }}>{daoName}</p>
    </div>
  )
}

export { DaoName }