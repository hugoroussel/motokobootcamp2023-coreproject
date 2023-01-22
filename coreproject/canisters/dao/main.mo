// Base data structures 
import List "mo:base/List";
import HashMap "mo:base/HashMap";
import Buffer "mo:base/Buffer";
import Array "mo:base/Array";
// Base basic types
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Nat64 "mo:base/Nat64";
import Int "mo:base/Int";
import Float "mo:base/Float";
import Blob "mo:base/Blob";
// Base identity
import Principal "mo:base/Principal";
// Base others
import Iter "mo:base/Iter";
import Option "mo:base/Option";
import Hash "mo:base/Hash";
import Time "mo:base/Time";
import Debug "mo:base/Debug";
// Types
import Types "./types";
// Helpers
import Helpers "./helpers";

actor class VODAO() = this {

    // TODO : change the actor principal id to the mainnet one
    let mbt : actor { 
        icrc1_balance_of: (Types.Account) -> async Nat;
        icrc1_transfer: (Types.TransferParameters) -> async Types.Result<Types.TxIndex, Types.TransferError>;
    } = actor(getMbtCanisterId());

    // TODO : change the actor principal id to the mainnet one
    let webpage : actor { set_last_proposal: (Text) -> async ();} = actor(getWebpageCanisterId());

    // DAO parameters
    var daoName: Text = "VodaDao";
    var thresholdAcceptance: Float = 100;
    var thresholdRejection: Float = -thresholdAcceptance;
    var minimumAmountOfVotingPower : Float = 1;
    var quadraticVotingEnabled : Bool = false;
    let env : Text = "mainnet";

    // Proposals initialization and reinstantiation via stable memory
    func nat64Hash(n : Nat64) : Hash.Hash { 
        Text.hash(Nat64.toText(n));
    };
    var id : Nat64 = 0;
    stable var proposalEntries : [(Nat64, Types.Proposal)] = [];
    let proposals = HashMap.fromIter<Nat64, Types.Proposal>(proposalEntries.vals(), Iter.size(proposalEntries.vals()), Nat64.equal, nat64Hash);

    // Neurons initialization and reinstantiation via stable memory
    stable var neuronsEntries : [(Principal, Types.Neuron)] = [];
    let neurons = HashMap.fromIter<Principal, Types.Neuron>(neuronsEntries.vals(), Iter.size(neuronsEntries.vals()), Principal.equal, Principal.hash);

    // The lastPassedProposal variable is the one reflected on the webpage canister and fully controlled by the dao. 
    // It is updated every time a proposal is accepted.
    var lastPassedProposal : Types.Proposal = {
        id=0;
        proposalText = "Initial Proposal";
        proposalType = #Standard;
        voters = List.nil<Principal>();
        numberOfVotes = 0;
        creator = Principal.fromText("qdaue-mb5vz-iszz7-w5r7p-o6t2d-fit3j-rwvzx-77nt4-jmqj7-z27oa-2ae");
        status = #OnGoing;
        time = Time.now()
    };

    // Submit a proposal to the DAO
    public shared ({caller}) func submitProposal(proposalText : Text, proposalType : Types.ProposalType) : async Types.DaoResult<(Bool), Types.CommonDaoError> {
        // Check if caller is not anonymous
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller"});
        };
        let neuron = neurons.get(caller);
        switch(neuron){
            case(null){
                return #CommonDaoError(#GenericError {message = "Caller has did not create a neuron"});
            };
            case(?neuron){
                 // assert await _checks(caller);
                var time = Time.now();
                // TODO : check if the proposal is not already in the DAO
                let proposal : Types.Proposal = {id=id; proposalText = proposalText; proposalType=proposalType; voters = List.nil<Principal>(); numberOfVotes = 0; creator = caller; status = #OnGoing; time = time};
                proposals.put(id, proposal);
                id += 1;
                #Ok(true);
            };
        };
    };

    // Vote for a proposal
    public shared ({caller}) func vote(id : Nat64, upvote : Bool) : async Types.DaoResult<(Bool), Types.CommonDaoError> {
        // check caller is not anonymous
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller"});
        };
        // check the voter voting power
        let neuron = neurons.get(caller);
        var votingPower : Float = 0;
        switch(neuron){
            case(null){
                return #CommonDaoError(#GenericError {message = "Voter has did not create a neuron"});
            };
            case(?neuron){
                    votingPower := await getNeuronVotingPower(neuron);
                }
        };
        let finalVotingPower = await normalizeVotingPower(votingPower);
        if(finalVotingPower < minimumAmountOfVotingPower){
            return #CommonDaoError(#GenericError {message = "Voter has not enough voting power"});
        };
        // check if the proposal exists
        let proposal = proposals.get(id);
        switch(proposal){
            case(null){
                return #CommonDaoError(#GenericError {message = "Proposal does not exist"});
            };
            case(?proposal){
                let hasVoted : ?Principal = List.find<Principal>(proposal.voters, func x = Principal.toText(x) == Principal.toText(caller));
                switch(hasVoted){
                    case(null){};
                    case(?hasVoted){
                        return #CommonDaoError(#GenericError {message = "User already voted on this proposal"});
                    };
                };
                var newNumberOfVotes : Float = 0;
                if (upvote){
                    newNumberOfVotes := proposal.numberOfVotes+finalVotingPower;
                } else {
                    newNumberOfVotes := proposal.numberOfVotes-finalVotingPower;
                };
                let newVoters : List.List<Principal> = List.push(caller, proposal.voters);

                if(newNumberOfVotes>=thresholdAcceptance){
                    switch(proposal.proposalType){
                    case(#Standard){};
                    case(#MinimumChange(args)){
                        if(args.newMinimum<=0){
                            return #CommonDaoError(#GenericError {message = "Minimum amount of voting power cannot be negative or null"});
                        };
                        minimumAmountOfVotingPower := args.newMinimum;
                    };
                    case(#ThresholdChange(args)){
                        thresholdAcceptance := args.newThreshold;
                    };
                    case(#ToggleQuadraticVoting){
                        quadraticVotingEnabled :=  not quadraticVotingEnabled;
                    };
                    };
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; proposalType = proposal.proposalType;voters = newVoters; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Accepted; time = proposal.time};
                    lastPassedProposal := updatedProposal;
                    await webpage.set_last_proposal(lastPassedProposal.proposalText);
                    proposals.put(proposal.id, updatedProposal);
                    return #Ok(true);
                } else if (newNumberOfVotes<=thresholdRejection){
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; proposalType = proposal.proposalType; voters = newVoters; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Rejected; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                    return #Ok(true);
                } else {
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; proposalType = proposal.proposalType; voters = newVoters; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #OnGoing; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                    return #Ok(true);
                }
            };
        };
    };

    // Neurons methods
    public shared ({caller}) func createNeuron(amount: Nat, dissolveDelay : Int) : async Types.DaoResult<(Bool), Types.CommonDaoError> {
        // no anonymous caller
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller"});
        };
        // check if the neuron already exists
        let mapEntry = neurons.get(caller);
        switch (mapEntry) {
            case (null) {};
            case(?neuron) {
                // neuron already exists
                if(neuron.neuronState == #Dissolved){/* neuron is dissolved, we can re-init it*/}
                else {
                    return #CommonDaoError(#GenericError {message = "Neuron already exists and is not dissolved"});
                };
            };
        };
        // check if the caller deposited enough tokens
        let canisterPrincipal = await idQuick();
        let callerSubAccount : Types.Subaccount =  await Helpers.accountIdentifier(canisterPrincipal, await Helpers.principalToSubaccount(caller));
        let depositAccount = {owner = canisterPrincipal; subaccount = ?callerSubAccount};
        let balance = await _getBalance(depositAccount);
        if(amount > balance){
            // user did not deposit enough :(
            return #CommonDaoError(#GenericError {message = "Not enough tokens deposited"});
        };
        // create the neuron
        let neuron = {
            owner = caller;
            amount = balance;
            dissolveDelay = dissolveDelay;
            neuronState = #Locked;
            createdAt = Time.now();
            dissolvedAt = 0;
            depositSubaccount : Types.Subaccount = callerSubAccount;
        };
        // add the neuron to the map
        neurons.put(caller, neuron);
        return #Ok(true);
    };

    // Dissolve the neuron. Called once to dissolve the neuron and a second time to get back the funds once the delay is over
    public shared ({caller}) func dissolveNeuron() : async Types.DaoResult<(Bool), Types.CommonDaoError> {
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller not allowed"});
        };
        let mapEntry : ?Types.Neuron = neurons.get(caller);
        switch(mapEntry){
            case(null){
                return #CommonDaoError(#GenericError {message = "User did not create a neuron"})
            };
            case(?neuron){
                switch(neuron.neuronState){
                    case(#Locked){
                        // user wants to start dissolving the neuron
                        let updatedNeuron = {
                            owner = neuron.owner;
                            amount = neuron.amount;
                            dissolveDelay = neuron.dissolveDelay;
                            neuronState = #Dissolving;
                            createdAt = neuron.createdAt;
                            dissolvedAt = Time.now();
                            depositSubaccount = neuron.depositSubaccount;
                        };
                        neurons.put(caller, updatedNeuron);
                        return #Ok(true);
                    };
                    case(#Dissolving){
                        if(neuron.createdAt+neuron.dissolveDelay < Time.now()){
                         let res = await _dissolveNeuron(caller, neuron);
                         return #Ok(true);
                        } else {
                            return #CommonDaoError(#GenericError {message = "Neuron is still dissolving"});
                        };
                    };
                    case (#Dissolved){
                        return #CommonDaoError(#GenericError {message = "Neuron is already dissolved"});
                    };
                }
            };
        };
    };

    private func _dissolveNeuron(caller : Principal, neuron : Types.Neuron) : async (Bool) {
           // neuron is ready to be dissolved and funds returned to the user
        let updatedNeuron = {
            owner = neuron.owner;
            amount = neuron.amount;
            dissolveDelay = neuron.dissolveDelay;
            neuronState = #Dissolved;
            createdAt = neuron.createdAt;
            dissolvedAt = neuron.dissolvedAt;
            depositSubaccount = neuron.depositSubaccount;
        };
        neurons.put(caller, updatedNeuron);
        // get the current balance of the neuron
        let canisterPrincipal = await idQuick();
        let depositAccount = {owner = canisterPrincipal; subaccount = ?neuron.depositSubaccount};
        let balance = await _getBalance(depositAccount);
        // send back the tokens to the user
        let transferParameters = {
            from_subaccount = ?neuron.depositSubaccount;
            to = {owner = caller; subaccount = null};
            amount = balance;
            fee = ?1000000;
            memo = null;
            created_at_time = null;
        };
        let res = await mbt.icrc1_transfer(transferParameters);
        return true;
    };

    public func normalizeVotingPower(votingPower : Float) : async Float {
        let normalizedVotingPower = votingPower / 100000000;
        if (quadraticVotingEnabled) {
            return Float.sqrt(normalizedVotingPower);
        };
        return normalizedVotingPower;
    };

    public func getNeuronVotingPower(neuron : Types.Neuron) : async Float {
        let canisterPrincipal = await idQuick();
        let depositAccount = {owner = canisterPrincipal; subaccount = ?neuron.depositSubaccount};
        let balance = await _getBalance(depositAccount);
        let dissolveDelayInMonths = await nanoSecondsToMonths(neuron.dissolveDelay);
        if(neuron.neuronState == #Dissolved){
            return 0;
        };
        if(neuron.neuronState == #Dissolving){
            let ageInMonths = await nanoSecondsToMonths(Time.now()-neuron.createdAt);
            let dissolveDelayInMonths = await nanoSecondsToMonths(Time.now() - neuron.dissolvedAt);
            var bonusAge : Float = await getAgeBonus(ageInMonths);
            var bonusDD : Float = await getDissolveBonus(dissolveDelayInMonths);
            return Float.fromInt(balance) * bonusAge * bonusDD;
        };
        if(neuron.neuronState == #Locked){
            let ageInMonths = await nanoSecondsToMonths(Time.now()-neuron.createdAt);
            let dissolveDelayInMonths = await nanoSecondsToMonths(neuron.dissolveDelay);
            var bonusAge : Float = await getAgeBonus(ageInMonths);
            var bonusDD : Float = await getDissolveBonus(dissolveDelayInMonths);
            return Float.fromInt(balance) * bonusAge * bonusDD;
        };
        return 0;
    };

    public func getAgeBonus(ageInMonths : Float) : async Float {
       if(ageInMonths >= 48){
            return 1.25;
        } else {
            return 0.005*ageInMonths+1;
        };
    };

    public func getDissolveBonus(dissolveDelayInMonths : Float) : async Float {
        if (dissolveDelayInMonths < 6) {
            return 1.0;
        } else if (dissolveDelayInMonths > 6 and dissolveDelayInMonths < 48) {
            return 0.01*dissolveDelayInMonths+0.997;
        } else {
            return 2.0;
        };
    };

    public func nanoSecondsToMonths(nanoSeconds : Int) : async Float {
        return Float.fromInt(nanoSeconds) / 2628000000000000;
    };

    // Helper functions
    
    // Returns a account derived from the canister's Principal and a subaccount. The subaccount is being derived from the caller's Principal.
    public shared ({ caller }) func getAddress() : async Types.Subaccount {
      let principalCanister = await idQuick();
      let subAcccount = await Helpers.principalToSubaccount(caller);
      return await Helpers.accountIdentifier(principalCanister, subAcccount);
    };

    private func getMbtCanisterId() : Text {
        if (Text.equal("mainnet", env)){
            return "db3eq-6iaaa-aaaah-abz6a-cai";
        } else {
            return "renrk-eyaaa-aaaaa-aaada-cai";
        };
    };

    private func getWebpageCanisterId() : Text {
        if (Text.equal("mainnet", env)){
            return "6gdk3-2aaaa-aaaap-qa5ma-cai";
        } else {
            return "rno2w-sqaaa-aaaaa-aaacq-cai";
        };
    };

    // Getters

    public func getMinimumVotingPower() : async Float {
        return minimumAmountOfVotingPower;
    };

    public func getThreshold() : async Float {
        return thresholdAcceptance;
    };

    public func getQuadraticVotingEnabled() : async Bool {
        return quadraticVotingEnabled;
    };


    public func getLastPassedProposal() : async Text {
        return lastPassedProposal.proposalText;
    };

    public query func getAllProposals() : async [Types.Proposal] {
        return Iter.toArray(proposals.vals());
    };

    public query func getProposal(id : Nat64) : async ?Types.Proposal {
        return proposals.get(id)
    };

    public func _getBalance(account : Types.Account) : async Nat {
        // let account = { owner = principal; subaccount = null };
        var res = await mbt.icrc1_balance_of(account);
        // res := res/100000000;
        return res;
    };

    public query func getDaoName() : async Text {
        return daoName;
    };

    public func idQuick() : async Principal {
        return Principal.fromActor(this);
    };

    public query func getNeuron(caller : Principal) : async ?Types.Neuron {
        return neurons.get(caller);
    };

    // Upgrade methods

    system func preupgrade() {
      proposalEntries := Iter.toArray(proposals.entries());
      neuronsEntries := Iter.toArray(neurons.entries());
    };

    system func postupgrade() {
      proposalEntries := [];
      neuronsEntries := [];
    };
}