import List "mo:base/List";
import Option "mo:base/Option";
import Types "./types";
import Map "mo:base/HashMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";
import Principal "mo:base/Principal";
import Blob "mo:base/Blob";

actor {

    public type Account = { owner : Principal; subaccount : ?Subaccount };
    public type Subaccount = Blob;


    var daoName: Text = "ActorDao";

    func natHash(n : Nat) : Hash.Hash { 
        Text.hash(Nat.toText(n));
    };

    // ; subaccount: ?Blob
    let mbt : actor { icrc1_balance_of: (Account) -> async Nat;} = actor("renrk-eyaaa-aaaaa-aaada-cai");

    var nextId : Nat = 0;

    var todos = Map.HashMap<Nat, Types.Proposal>(0, Nat.equal, natHash);

    public shared ({caller}) func submit_proposal(proposalText : Text) : async Nat {
        let balance = await getBalance(caller);
        assert(balance >= 1);
        let id = nextId;
        todos.put(id, { newProposal = proposalText; numberOfVotes = 0 });
        nextId += 1;
        id
    };

    public query func getProposals() : async [Types.Proposal] {
        Iter.toArray(todos.vals());
    };

    public query func getDaoName() : async Text {
        return daoName;
    };

    public func getBalance(caller : Principal) : async Nat {
        // let principal = Principal.fromText("yqize-texcq-goob5-6iwmq-3lflv-cmxvs-u5u7o-5fha2-mpmgj-tclpa-nqe");
        let principal = caller;
        let account = { owner = principal; subaccount = null };
        let res = await mbt.icrc1_balance_of(account);
        return res;
    };
}