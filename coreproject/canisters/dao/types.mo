import HashMap "mo:base/HashMap";
import List "mo:base/List";

module {

    // Dao types
    public type ProposalStatus = {
        #OnGoing;
        #Rejected;
        #Accepted;
    };

    public type ProposalType = {
        #Standard;
        #MinimumChange : MinimumChange;
        #ThresholdChange : ThresholdChange;
        #ToggleQuadraticVoting;
    };

    public type MinimumChange = {
        newMinimum: Float;
    };

    public type ThresholdChange = {
        newThreshold: Float;
    };

    public type Proposal = {
        id: Nat64;
        proposalType: ProposalType;
        proposalText: Text;
        numberOfVotes: Float;
        voters : List.List<Principal>;
        creator: Principal;
        status: ProposalStatus;
        time: Int;
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
        depositSubaccount: Subaccount;
        isFollowing: ?Neuron;
        isFollowedBy: List.List<Neuron>;
    };

    public type CommonDaoError = {
        #GenericError : {message : Text };
    };

    public type DaoResult<T, E> = { #Ok : T; #CommonDaoError : E };

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

    public type TransferParameters = {
        from_subaccount : ?Subaccount;
        to : Account;
        amount : Tokens;
        fee : ?Tokens;
        memo : ?Memo;
        created_at_time : ?Timestamp;
    };
}