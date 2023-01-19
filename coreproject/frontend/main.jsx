import React from "react"
import ReactDOM from "react-dom"
import "./index.css"
import App from "./App"
import NewProposal from "./NewProposal"
import Locking from "./Locking"

import {
  BrowserRouter as Router,
  Routes,
  Route,
  Link
} from "react-router-dom";

ReactDOM.render(
  <React.StrictMode>
    <Router>
     <Routes>
          <Route exact path="/">
            <Route exact path='/' element={<App/>}/>
          </Route>
          <Route path="/new">
            <Route exact path='/new' element={<NewProposal/>}/>
          </Route>
          <Route path="/lock">
            <Route exact path='/lock' element={<Locking/>}/>
          </Route>
    </Routes>
    </Router>
  </React.StrictMode>,
  document.getElementById("root"),
)
