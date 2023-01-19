import Text "mo:base/Text";
import Time "mo:base/Time";
import Principal "mo:base/Principal";
import HashMap "mo:base/HashMap";

actor {
    type StreamingCallbackHttpResponse = {
        body: Blob;
        token: ?Token;
    };

    type Token = {
        // Add whatever fields you'd like
        arbitrary_data: Text;
    };

    type CallbackStrategy = {
        callback: shared query (Token) -> async StreamingCallbackHttpResponse;
        token: Token;
    };

    type StreamingStrategy =  {
        #Callback: CallbackStrategy;
    };

    type HeaderField = (Text, Text);

    type HttpResponse = {
        status_code: Nat16;
        headers: [HeaderField];
        body: Blob;
        streaming_strategy: ?StreamingStrategy;
        upgrade: ?Bool;
    };

    type HttpRequest = {
        method: Text;
        url: Text;
        headers: [HeaderField];
        body: Blob;
    };

    public type Proposal = {
        id: Nat64;
        proposalText: Text;
        voters: HashMap.HashMap<Principal, Bool>;
        numberOfVotes: Int;
        creator: Principal;
        status: ProposalStatus;
        time: Time.Time;
    };


    type ProposalStatus = {
        #OnGoing;
        #Rejected;
        #Accepted;
    };

    // let dao : actor { get_last_passed_proposal: () -> async Text;} = actor("rkp4c-7iaaa-aaaaa-aaaca-cai");

    var last_proposal : Text = "No proposal yet";

    public shared ({caller}) func set_last_proposal(proposal: Text) : () {
        // TODO : not sure this works
        assert caller == Principal.fromText("rkp4c-7iaaa-aaaaa-aaaca-cai");
        last_proposal := proposal;
    };


    public query func http_request(req: HttpRequest) : async HttpResponse {
        // let proposal = await get_last_passed_proposal();
        return({
            body = Text.encodeUtf8("Last passed proposal of the DAO is "#last_proposal);
            headers = [];
            status_code = 200;
            streaming_strategy = null;
            upgrade = null;
        })
    };

    /*
    public func get_last_passed_proposal() : async Text {
        return await dao.get_last_passed_proposal();
    };
    */
}