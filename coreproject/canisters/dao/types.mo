import HashMap "mo:base/HashMap";

module {
     // Everything related to calling the MB token.
    public type Account = { owner : Principal; subaccount : ?Subaccount };
    public type Subaccount = Blob;
}