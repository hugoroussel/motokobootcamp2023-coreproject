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
        assert await _checks(caller);
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
        assert await _checks(caller);
        // Check if the proposal exists
        var proposal = proposals.get(id);
        // Get user balance 
        let balance = await _getBalance(Principal.toText(caller));
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
        age: Int;
    };

    // Neurons methods

    let defaultSubaccount : Types.Subaccount = Blob.fromArrayMut(Array.init(32, 0 : Nat8));

    // public shared ({caller}) func lock() : async Result<TxIndex, TransferFromError> {
    public shared ({caller}) func unlock() : async Types.Result<Types.TxIndex, Types.TransferFromError> {
        let canisterPrincipal = await idQuick();
        let subAccount : Types.Subaccount = await Helpers.accountIdentifier(canisterPrincipal, await Helpers.principalToSubaccount(caller));
        let from : Types.Account = {owner: Principal = canisterPrincipal; subaccount: ?Blob = ?subAccount};
        let to : Types.Account = {owner: Principal = caller; subaccount: ?Blob = null};
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

    public func _getBalance(caller : Text) : async Nat {
        let principal = Principal.fromText(caller);
        let account = { owner = principal; subaccount = null };
        var res = await mbt.icrc1_balance_of(account);
        res := res/100000000;
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
    };

    system func postupgrade() {
      proposalEntries := [];
    };
}