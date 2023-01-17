import List "mo:base/List";
import Option "mo:base/Option";
import Types "./types";
import Map "mo:base/HashMap";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat "mo:base/Nat";
import Iter "mo:base/Iter";


actor {

    var daoName: Text = "ActorDao";

    func natHash(n : Nat) : Hash.Hash { 
        Text.hash(Nat.toText(n));
    };

    var nextId : Nat = 0;

    var todos = Map.HashMap<Nat, Types.Proposal>(0, Nat.equal, natHash);

    public func addProposal(proposalText : Text) : async Nat {
        let id = nextId;
        todos.put(id, { newProposal = proposalText; numberOfVotes = 0 });
        nextId += 1;
        id
    };

    public query func getProposals() : async [Types.Proposal] {
        Iter.toArray(todos.vals());
    };

    public query func getDaoName() :async Text {
        return daoName;
    };
}