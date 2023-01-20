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
    } = actor("renrk-eyaaa-aaaaa-aaada-cai");

    // TODO : change the actor principal id to the mainnet one
    let webpage : actor { set_last_proposal: (Text) -> async ();} = actor("rno2w-sqaaa-aaaaa-aaacq-cai");

    // DAO parameters
    var daoName: Text = "VodaDao";
    var thresholdAcceptance: Int = 100;
    var thresholdRejection: Int = -100;
    var timeLastUpdated : Int = 0;

    // Proposals initialization and reinstantiation via stable memory
    func nat64Hash(n : Nat64) : Hash.Hash { 
        Text.hash(Nat64.toText(n));
    };
    var id : Nat64 = 0;
    stable var proposalEntries : [(Nat64, Types.Proposal)] = [];
    let proposals = HashMap.fromIter<Nat64, Types.Proposal>(proposalEntries.vals(), Iter.size(proposalEntries.vals()), Nat64.equal, nat64Hash);

    // Neurons initialization and reinstantiation via stable memory
    stable var neuronsEntries : [(Principal, Neuron)] = [];
    let neurons = HashMap.fromIter<Principal, Neuron>(neuronsEntries.vals(), Iter.size(neuronsEntries.vals()), Principal.equal, Principal.hash);

    // The lastPassedProposal variable is the one reflected on the webpage canister and fully controlled by the dao. 
    // It is updated every time a proposal is accepted.
    var lastPassedProposal : Types.Proposal = {
        id=0;
        proposalText = "Initial Proposal";
        voters = List.nil<Principal>();
        numberOfVotes = 0;
        creator = Principal.fromText("qdaue-mb5vz-iszz7-w5r7p-o6t2d-fit3j-rwvzx-77nt4-jmqj7-z27oa-2ae");
        status = #OnGoing;
        time = Time.now()
    };

    // Submit a proposal to the DAO
    public shared ({caller}) func submit_proposal(proposalText : Text) : async Bool {
        // Checks
        // assert await _checks(caller);
        var time = Time.now();
        // TODO : check if the proposal is not already in the DAO
        let proposal = {id=id; proposalText = proposalText; voters = List.nil<Principal>(); numberOfVotes = 0; creator = caller; status = #OnGoing; time = time};
        proposals.put(id, proposal);
        id += 1;
        return true;
    };

    // Vote on a proposal, if upvote is true the vote will be positive (currentAmountOfVotes + balance), if false the vote will be negative (currentAmountOfVotes - balance)
    public shared ({caller}) func vote(id : Nat64, upvote : Bool) : async Bool {
        // Standard Identity Checks
        // assert await _checks(caller);
        // Check if the proposal exists
        var proposal = proposals.get(id);
        // Get user balance 
        // let account = 
        let balance = 0;// await _getBalance(Principal.toText(caller));
        var newNumberOfVotes : Int = balance;
        switch(proposal){
            case(null){
                return false;
            };
            case(?proposal){
                if(proposal.status != #OnGoing){
                    // Cannot vote on a proposal that is not ongoing
                    assert false;
                };
                // check if the user has already voted
                let hasVoted : ?Principal = List.find<Principal>(proposal.voters, func x = Principal.toText(x) == Principal.toText(caller));
                switch(hasVoted){
                    case(null){
                        // User has not voted yet
                    };
                    case(?hasVoted){
                        // User has already voted
                        assert false;
                        // return false;
                    };
                };
                if (upvote){
                    newNumberOfVotes := proposal.numberOfVotes+balance;
                } else {
                    newNumberOfVotes := proposal.numberOfVotes-balance;
                };
                Debug.print(Int.toText(newNumberOfVotes));
                let newVoters : List.List<Principal> = List.push(caller, proposal.voters);
                if(newNumberOfVotes>=thresholdAcceptance){
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; voters = newVoters; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Accepted; time = proposal.time};
                    lastPassedProposal := updatedProposal;
                    await webpage.set_last_proposal(lastPassedProposal.proposalText);
                    proposals.put(proposal.id, updatedProposal);
                } else if (newNumberOfVotes<=thresholdRejection){
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; voters = newVoters; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Rejected; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                } else {
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; voters = newVoters; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #OnGoing; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                };
                return true;
            };
        };   
    };

    // Time
    public shared func getTime() : async Int {
        return timeLastUpdated;
    };

    public shared func setTime() : async Bool {
        timeLastUpdated := Time.now();
        return true;
    };

    // Neurons types
    public type NeuronState = {
        #Locked;
        #Dissolving;
        #Dissolved;
    };

    public type Neuron = {
        owner: Principal;
        amount: Nat;
        dissolveDelay: Int;
        neuronState: NeuronState;
        createdAt: Int;
        dissolvedAt: Int;
        depositSubaccount: Types.Subaccount;
    };

    public type CommonError = {
        #GenericError : {message : Text };
    };

    public type Result<T, E> = { #Ok : T; #CommonError : E };

    // Neurons methods

    public shared ({caller}) func createNeuron(amount: Nat, dissolveDelay : Int) : async Result<(Bool), CommonError> {
        // no anonymous caller
        if(Principal.isAnonymous(caller)) {
            return #CommonError(#GenericError {message = "Anonymous caller"});
        };
        // check if the neuron already exists
        let mapEntry = neurons.get(caller);
        switch (mapEntry) {
            case (null) {
                // neuron does not exist all good
            };
            case(?neuron) {
                // neuron already exists
                // return #CommonError(#GenericError {message = "Neuron already exists"});
                if(neuron.neuronState == #Dissolved){
                    // neuron is dissolved, we can re-init it
                } else {
                    // neuron is not dissolved, we cannot re-init it
                    return #CommonError(#GenericError {message = "Neuron already exists"});
                };
            };
        };
        // check if the caller deposited enough tokens
        let canisterPrincipal = await idQuick();
        let callerSubAccount : Types.Subaccount =  await Helpers.accountIdentifier(canisterPrincipal, await Helpers.principalToSubaccount(caller));
        let depositAccount = {owner = canisterPrincipal; subaccount = ?callerSubAccount};
        let balance = await _getBalance(depositAccount);
        Debug.print("Balance : " # Nat.toText(balance));
        Debug.print("Amount : " # Nat.toText(amount));
        if(amount < balance){
            // user did not deposit enough :(
            return #CommonError(#GenericError {message = "Not enough tokens deposited"});

        };
        Debug.print("Amount : " # Nat.toText(amount));
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

    public shared ({caller}) func dissolveNeuron() : async (Bool) {
        // no anonymous caller
        if(Principal.isAnonymous(caller)) {
            return false;
        };
        let mapEntry : ?Neuron = neurons.get(caller);
        switch(mapEntry){
            case(null){return false;};
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
                        return true;
                    };
                    case(#Dissolving){
                        if(neuron.createdAt+neuron.dissolveDelay < Time.now()){
                         return await _dissolveNeuron(caller, neuron);
                        } else {
                            // neuron is not ready to be dissolved
                            return false;
                        };
                    };
                    case (#Dissolved){
                        // neuron is already dissolved
                        return false;
                    };
                }
            };
        };
        return true;
    };

    private func _dissolveNeuron(caller : Principal, neuron : Neuron) : async (Bool) {
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
            fee = null;
            memo = null;
            created_at_time = null;
        };
        let res = await mbt.icrc1_transfer(transferParameters);
        return true;
    };

    public func getNeuronVotingPower(neuron : Neuron) : async Float {
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


    let defaultSubaccount : Types.Subaccount = Blob.fromArrayMut(Array.init(32, 0 : Nat8));

    // public shared ({caller}) func lock() : async Result<TxIndex, TransferFromError> {
    public shared ({caller}) func unlock() : async Types.Result<Types.TxIndex, Types.TransferFromError> {
        let canisterPrincipal = await idQuick();
        let subAccount : Types.Subaccount = await Helpers.accountIdentifier(canisterPrincipal, await Helpers.principalToSubaccount(caller));
        let from : Types.Account = {owner: Principal = canisterPrincipal; subaccount: ?Types.Subaccount = ?subAccount};
        let to : Types.Account = {owner: Principal = caller; subaccount: ?Types.Subaccount = null};
        let transferFrom : Types.TransferParameters = {
            from_subaccount = ?subAccount;
            to = to;
            amount = 100000000;
            fee = null;
            memo = null;
            created_at_time = null;
        };
        await mbt.icrc1_transfer(transferFrom);
        // return true;
    };

    // Helper functions
    
    // Returns a account derived from the canister's Principal and a subaccount. The subaccount is being derived from the caller's Principal.
    public shared ({ caller }) func getAddress() : async Types.Subaccount {
      Debug.print("caller getAddress");
      Debug.print(Principal.toText(caller));
      let principalCanister = await idQuick();
      let subAcccount = await Helpers.principalToSubaccount(caller);
      return await Helpers.accountIdentifier(principalCanister, subAcccount);
    };

    // Getters

    public func get_lastPassedProposal() : async Text {
        return lastPassedProposal.proposalText;
    };

    public query func get_all_proposals() : async [Types.Proposal] {
        return Iter.toArray(proposals.vals());
    };

    public query func get_proposal(id : Nat64) : async ?Types.Proposal {
        return proposals.get(id)
    };

    // Private functions
    /*
    private func _checks(caller: Principal) : async Bool {
        // no anonymous submissions
        if(Principal.isAnonymous(caller)) {
            return false;
        };
        // check if the caller is part of the DAO, i.e has a balance of 1 or more MBT
        let balance = await _getBalance(Principal.toText(caller));
        // TODO: check here should take into account decimals
        if(balance < 1) {
            return false;
        };
        return true;
    };
    */

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