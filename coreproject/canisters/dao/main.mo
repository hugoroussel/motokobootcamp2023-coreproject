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

    var daoName: Text = "ActorDao";

    type ProposalStatus = {
        #OnGoing;
        #Rejected;
        #Accepted;
    };

    public type Proposal = {
        id: Nat64;
        newProposal: Text;
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


    public shared ({caller}) func submit_proposal(proposalText : Text) : async Bool {
        // Checks
        assert await _checks(caller);
        // check if the proposal is not already in the DAO
        let proposal = {id=id; newProposal = proposalText; numberOfVotes = 0; creator = caller; status = #OnGoing; time = Time.now()};
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
        let balance = await _getBalance(caller);
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
                    var updatedProposal = {id=proposal.id; newProposal = proposal.newProposal; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Accepted; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                } else if (newNumberOfVotes<=-100){
                    var updatedProposal = {id=proposal.id; newProposal = proposal.newProposal; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Rejected; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                } else {
                    var updatedProposal = {id=proposal.id; newProposal = proposal.newProposal; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Rejected; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                };
                return true;
            };
        };
        
    };

    // Getters

    public query func get_all_proposals() : async [Proposal] {
        return Iter.toArray(proposals.vals());
    };


    public query func get_proposal(id : Nat64) : async ?Proposal {
        return proposals.get(Text.hash(text))
    };

    // Private functions

    private func _checks(caller: Principal) : async Bool {
        // no anonymous submissions
        if(Principal.isAnonymous(caller)) {
            return false;
        };
        // check if the caller is part of the DAO, i.e has a balance of 1 or more MBT
        let balance = await _getBalance(caller);
        // TODO: check here should take into account decimals
        if(balance < 1) {
            return false;
        };
        return true;
    };

    private func _getBalance(caller : Principal) : async Nat {
        let principal = caller;
        let account = { owner = principal; subaccount = null };
        let res = await mbt.icrc1_balance_of(account);
        return res;
    };

    public query func getDaoName() : async Text {
        return daoName;
    };
}