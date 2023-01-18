import List "mo:base/List";
import Option "mo:base/Option";
import HashMap "mo:base/HashMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";
import Nat64 "mo:base/Nat64";
import Time "mo:base/Time";
import Int "mo:base/Int";


actor {

    // Everything related to calling the MB token.
    public type Account = { owner : Principal; subaccount : ?Subaccount };
    public type Subaccount = Blob;
    let mbt : actor { icrc1_balance_of: (Account) -> async Nat;} = actor("renrk-eyaaa-aaaaa-aaada-cai");
    let webpage : actor { set_last_proposal: (Proposal) -> async ();} = actor("rno2w-sqaaa-aaaaa-aaacq-cai");

    var daoName: Text = "ActorDao";

    type ProposalStatus = {
        #OnGoing;
        #Rejected;
        #Accepted;
    };

    public type Proposal = {
        id: Nat64;
        proposalText: Text;
        numberOfVotes: Int;
        creator: Principal;
        status: ProposalStatus;
        time: Time.Time;
    };

    func nat64Hash(n : Nat64) : Hash.Hash { 
        Text.hash(Nat64.toText(n));
    };
    var id : Nat64 = 0;
    var proposals = HashMap.HashMap<Nat64, Proposal>(0, Nat64.equal, nat64Hash);

    // Initialized for debugging purposes
    var last_passed_proposal : Proposal = {id=0; proposalText = "Initial Proposal"; numberOfVotes = 0; creator = Principal.fromText("qdaue-mb5vz-iszz7-w5r7p-o6t2d-fit3j-rwvzx-77nt4-jmqj7-z27oa-2ae"); status = #OnGoing; time = Time.now()};


    public shared ({caller}) func submit_proposal(proposalText : Text) : async Bool {
        // Checks
        assert await _checks(caller);
        // check if the proposal is not already in the DAO
        let proposal = {id=id; proposalText = proposalText; numberOfVotes = 0; creator = caller; status = #OnGoing; time = Time.now()};
        proposals.put(id, proposal);
        id += 1;
        return true;
    };

    public shared ({caller}) func vote(id : Nat64, upvote : Bool) : async Bool {
        // Checks
        assert await _checks(caller);
        // check if the proposal exists
        var proposal = proposals.get(id);
        // get user balance
        let balance = await _getBalance(Principal.toText(caller));
        var newNumberOfVotes : Int = balance;
        switch(proposal){
            case(null){
                return false;
            };
            case(?proposal){
                if(proposal.status != #OnGoing){
                    // Cannot vote on a proposal that is not ongoing
                    return false;
                };
                if (upvote){
                    newNumberOfVotes := balance+proposal.numberOfVotes;
                } else {
                    newNumberOfVotes := proposal.numberOfVotes-balance;
                };
                if(newNumberOfVotes>=100){
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Accepted; time = proposal.time};
                    last_passed_proposal := updatedProposal;
                    await webpage.set_last_proposal(last_passed_proposal);
                    proposals.put(proposal.id, updatedProposal);
                } else if (newNumberOfVotes<=-100){
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Rejected; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                } else {
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Rejected; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                };
                return true;
            };
        };
        
    };

    // Getters

    public func get_last_passed_proposal() : async Text {
        return last_passed_proposal.proposalText;
    };

    public query func get_all_proposals() : async [Proposal] {
        return Iter.toArray(proposals.vals());
    };

    public query func get_proposal(id : Nat64) : async ?Proposal {
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
        let res = await mbt.icrc1_balance_of(account);
        return res;
    };

    public query func getDaoName() : async Text {
        return daoName;
    };
}