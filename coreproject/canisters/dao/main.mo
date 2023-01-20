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
import Debug "mo:base/Debug";
import Array "mo:base/Array";
import SHA224 "./SHA224";
import CRC32 "./CRC32";
import Nat8 "mo:base/Nat8";
import Nat32 "mo:base/Nat32";
import Buffer "mo:base/Buffer";


actor class VODAO() = this {

    // Everything related to calling the MB token.
    public type Account = { owner : Principal; subaccount : ?Subaccount };
    public type Tokens = Nat;
    public type Memo = Blob;
    public type Timestamp = Nat64;
    public type Result<T, E> = { #Ok : T; #Err : E };
    public type TxIndex = Nat;
    public type Operation = {
        #Approve : Approve;
        #Transfer : Transfer;
        #Burn : Transfer;
        #Mint : Transfer;
    };
    public type CommonFields = {
        memo : ?Memo;
        fee : ?Tokens;
        created_at_time : ?Timestamp;
    };
    public type Approve = CommonFields and {
        from : Account;
        spender : Principal;
        amount : Int;
        expires_at : ?Nat64;
    };
    public type TransferSource = {
        #Init;
        #Icrc1Transfer;
        #Icrc2TransferFrom;
    };
    public type Transfer = CommonFields and {
        spender : Principal;
        source : TransferSource;
        to : Account;
        from : Account;
        amount : Tokens;
    };
    public type Allowance = { allowance : Nat; expires_at : ?Nat64 };
    public type Transaction = {
        operation : Operation;
        // Effective fee for this transaction.
        fee : Tokens;
        timestamp : Timestamp;
    };
    public type DeduplicationError = {
        #TooOld;
        #Duplicate : { duplicate_of : TxIndex };
        #CreatedInFuture : { ledger_time : Timestamp };
    };
    public type CommonError = {
        #InsufficientFunds : { balance : Tokens };
        #BadFee : { expected_fee : Tokens };
        #TemporarilyUnavailable;
        #GenericError : { error_code : Nat; message : Text };
    };
    public type TransferError = DeduplicationError or CommonError or {
        #BadBurn : { min_burn_amount : Tokens };
    };
    public type ApproveError = DeduplicationError or CommonError or {
        #Expired : { ledger_time : Nat64 };
    };
    public type TransferFromError = TransferError or {
        #InsufficientAllowance : { allowance : Nat };
    };

    public type Subaccount = Blob;

    public type TransferFrom = {
        from : Account;
        to : Account;
        amount : Tokens;
        fee : ?Tokens;
        memo : ?Memo;
        created_at_time : ?Timestamp;
    };


    let mbt : actor { 
        icrc1_balance_of: (Account) -> async Nat;
        icrc2_transfer_from: (TransferFrom) -> async  Result<TxIndex, TransferFromError>;
    } = actor("renrk-eyaaa-aaaaa-aaada-cai");
    let webpage : actor { set_last_proposal: (Text) -> async ();} = actor("rno2w-sqaaa-aaaaa-aaacq-cai");

    var daoName: Text = "VodaDao";
    var thresholdAcceptance: Int = 100;
    var thresholdRejection: Int = -100;

    type ProposalStatus = {
        #OnGoing;
        #Rejected;
        #Accepted;
    };

    public type Proposal = {
        id: Nat64;
        proposalText: Text;
        numberOfVotes: Int;
        voters : List.List<Principal>;
        creator: Principal;
        status: ProposalStatus;
        time: Int;
    };

    func nat64Hash(n : Nat64) : Hash.Hash { 
        Text.hash(Nat64.toText(n));
    };
    var id : Nat64 = 0;

    stable var proposalEntries : [(Nat64, Proposal)] = [];
    let proposals = HashMap.fromIter<Nat64,Proposal>(proposalEntries.vals(), Iter.size(proposalEntries.vals()), Nat64.equal, nat64Hash);
    // var proposals = HashMap.HashMap<Nat64, Proposal>(0, Nat64.equal, nat64Hash);

    var emptyHashMap = HashMap.HashMap<Principal, Bool>(0, Principal.equal, Principal.hash);

    // Initialized for debugging purposes
    var last_passed_proposal : Proposal = {
        id=0;
        proposalText = "Initial Proposal";
        voters = List.nil<Principal>();
        numberOfVotes = 0;
        creator = Principal.fromText("qdaue-mb5vz-iszz7-w5r7p-o6t2d-fit3j-rwvzx-77nt4-jmqj7-z27oa-2ae");
        status = #OnGoing;
        time = Time.now()
        };

    public shared ({caller}) func submit_proposal(proposalText : Text) : async Bool {
        // Checks
        assert await _checks(caller);
        let time = Time.now();
        // check if the proposal is not already in the DAO
        let proposal = {id=id; proposalText = proposalText; voters = List.nil<Principal>(); numberOfVotes = 0; creator = caller; status = #OnGoing; time = time};
        proposals.put(id, proposal);
        id += 1;
        return true;
    };

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
                    last_passed_proposal := updatedProposal;
                    await webpage.set_last_proposal(last_passed_proposal.proposalText);
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

    // Neurons functions
    let defaultSubaccount : Subaccount = Blob.fromArrayMut(Array.init(32, 0 : Nat8));

    public shared ({caller}) func lock() : async Result<TxIndex, TransferFromError> {
        Debug.print("Locking");
        Debug.print(Principal.toText(caller));
        let callerAccount : Account = {owner: Principal = caller; subaccount: ?Blob = ?defaultSubaccount};
        let dao : Account = {owner : Principal = await idQuick(); subaccount = ?defaultSubaccount};
        let transferFrom : TransferFrom = {
            from = callerAccount;
            to = dao;
            amount = 100000000;
            fee = null;
            memo = null;
            created_at_time = null;
        };
        await mbt.icrc2_transfer_from(transferFrom);
        // return true;
    };

    // Helpers
    public func beBytes(n : Nat32) : async [Nat8] {
        func byte(n : Nat32) : Nat8 {
            Nat8.fromNat(Nat32.toNat(n & 0xff))
        };
        [byte(n >> 24), byte(n >> 16), byte(n >> 8), byte(n)]
    };

    public func principalToSubaccount(principal: Principal) : async Blob {
      let idHash = SHA224.Digest();
        idHash.write(Blob.toArray(Principal.toBlob(principal)));
        let hashSum = idHash.sum();
        let crc32Bytes = await beBytes(CRC32.ofArray(hashSum));
        let buf = Buffer.Buffer<Nat8>(32);
        let blob = Blob.fromArray(Array.append(crc32Bytes, hashSum));
        return blob;
    };

    public type AccountIdentifier = Blob;
  
    public func accountIdentifier(principal: Principal, subaccount: Subaccount) : async AccountIdentifier {
        let hash = SHA224.Digest();
        hash.write([0x0A]);
        hash.write(Blob.toArray(Text.encodeUtf8("account-id")));
        hash.write(Blob.toArray(Principal.toBlob(principal)));
        hash.write(Blob.toArray(subaccount));
        let hashSum = hash.sum();
        let crc32Bytes = await beBytes(CRC32.ofArray(hashSum));
        Blob.fromArray(Array.append(crc32Bytes, hashSum))
    };

    public shared ({ caller }) func getAddress() : async AccountIdentifier {
      // Returns a account derived from the canister's Principal and a subaccount. The subaccount is being derived from the caller's Principal.
      let principalCanister = await idQuick();
      let subAcccount = await principalToSubaccount(caller);
      return await accountIdentifier(principalCanister, subAcccount);
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

    // upgrade methods
     system func preupgrade() {
      proposalEntries := Iter.toArray(proposals.entries());
    };

    system func postupgrade() {
      proposalEntries := [];
    };
}