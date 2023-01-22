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
    } = actor(getMbtCanisterId());

    // TODO : change the actor principal id to the mainnet one
    let webpage : actor { set_last_proposal: (Text) -> async ();} = actor(getWebpageCanisterId());

    // DAO parameters
    var daoName: Text = "VodaDao";
    var thresholdAcceptance: Float = 100;
    var thresholdRejection: Float = -thresholdAcceptance;
    var minimumAmountOfVotingPower : Float = 1;
    var quadraticVotingEnabled : Bool = false;
    let env : Text = "mainnet";

    // Proposals initialization and reinstantiation via stable memory
    func nat64Hash(n : Nat64) : Hash.Hash { 
        Text.hash(Nat64.toText(n));
    };
    var id : Nat64 = 0;
    stable var proposalEntries : [(Nat64, Types.Proposal)] = [];
    let proposals = HashMap.fromIter<Nat64, Types.Proposal>(proposalEntries.vals(), Iter.size(proposalEntries.vals()), Nat64.equal, nat64Hash);

    // Neurons initialization and reinstantiation via stable memory
    stable var neuronsEntries : [(Principal, Types.Neuron)] = [];
    let neurons = HashMap.fromIter<Principal, Types.Neuron>(neuronsEntries.vals(), Iter.size(neuronsEntries.vals()), Principal.equal, Principal.hash);

    // The lastPassedProposal variable is the one reflected on the webpage canister and fully controlled by the dao. 
    // It is updated every time a proposal is accepted.
    var lastPassedProposal : Types.Proposal = {
        id=0;
        proposalText = "Initial Proposal";
        proposalType = #Standard;
        voters = List.nil<Principal>();
        numberOfVotes = 0;
        creator = Principal.fromText("qdaue-mb5vz-iszz7-w5r7p-o6t2d-fit3j-rwvzx-77nt4-jmqj7-z27oa-2ae");
        status = #OnGoing;
        time = Time.now()
    };

    // Submit a proposal to the DAO
    public shared ({caller}) func submitProposal(proposalText : Text, proposalType : Types.ProposalType) : async Types.DaoResult<(Bool), Types.CommonDaoError> {
        // Check if caller is not anonymous
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller"});
        };
        let neuron = neurons.get(caller);
        switch(neuron){
            case(null){
                return #CommonDaoError(#GenericError {message = "Caller has did not create a neuron"});
            };
            case(?neuron){
                 // assert await _checks(caller);
                var time = Time.now();
                // TODO : check if the proposal is not already in the DAO
                let proposal : Types.Proposal = {id=id; proposalText = proposalText; proposalType=proposalType; voters = List.nil<Principal>(); numberOfVotes = 0; creator = caller; status = #OnGoing; time = time};
                proposals.put(id, proposal);
                id += 1;
                #Ok(true);
            };
        };
    };

    // Vote for a proposal
    public shared ({caller}) func vote(id : Nat64, upvote : Bool) : async Types.DaoResult<(Bool), Types.CommonDaoError> {
        // check caller is not anonymous
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller"});
        };
        // check the voter voting power
        let neuron = neurons.get(caller);
        var votingPower : Float = 0;
        switch(neuron){
            case(null){
                return #CommonDaoError(#GenericError {message = "Voter has did not create a neuron"});
            };
            case(?neuron){
                    votingPower := await getNeuronTotalVotingPower(neuron);
                }
        };
        let finalVotingPower = await normalizeVotingPower(votingPower);
        if(finalVotingPower < minimumAmountOfVotingPower){
            return #CommonDaoError(#GenericError {message = "Voter has not enough voting power"});
        };
        // check if the proposal exists
        let proposal = proposals.get(id);
        switch(proposal){
            case(null){
                return #CommonDaoError(#GenericError {message = "Proposal does not exist"});
            };
            case(?proposal){
                let hasVoted : ?Principal = List.find<Principal>(proposal.voters, func x = Principal.toText(x) == Principal.toText(caller));
                switch(hasVoted){
                    case(null){};
                    case(?hasVoted){
                        return #CommonDaoError(#GenericError {message = "User already voted on this proposal"});
                    };
                };
                var newNumberOfVotes : Float = 0;
                if (upvote){
                    newNumberOfVotes := proposal.numberOfVotes+finalVotingPower;
                } else {
                    newNumberOfVotes := proposal.numberOfVotes-finalVotingPower;
                };
                let newVoters : List.List<Principal> = List.push(caller, proposal.voters);

                if(newNumberOfVotes>=thresholdAcceptance){
                    switch(proposal.proposalType){
                    case(#Standard){};
                    case(#MinimumChange(args)){
                        if(args.newMinimum<=0){
                            return #CommonDaoError(#GenericError {message = "Minimum amount of voting power cannot be negative or null"});
                        };
                        minimumAmountOfVotingPower := args.newMinimum;
                    };
                    case(#ThresholdChange(args)){
                        thresholdAcceptance := args.newThreshold;
                    };
                    case(#ToggleQuadraticVoting){
                        quadraticVotingEnabled :=  not quadraticVotingEnabled;
                    };
                    };
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; proposalType = proposal.proposalType;voters = newVoters; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Accepted; time = proposal.time};
                    lastPassedProposal := updatedProposal;
                    await webpage.set_last_proposal(lastPassedProposal.proposalText);
                    proposals.put(proposal.id, updatedProposal);
                    return #Ok(true);
                } else if (newNumberOfVotes<=thresholdRejection){
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; proposalType = proposal.proposalType; voters = newVoters; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #Rejected; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                    return #Ok(true);
                } else {
                    var updatedProposal = {id=proposal.id; proposalText = proposal.proposalText; proposalType = proposal.proposalType; voters = newVoters; numberOfVotes = newNumberOfVotes; creator = proposal.creator; status = #OnGoing; time = proposal.time};
                    proposals.put(proposal.id, updatedProposal);
                    return #Ok(true);
                }
            };
        };
    };

    // Neurons methods
    public shared ({caller}) func createNeuron(amount: Nat, dissolveDelay : Int) : async Types.DaoResult<(Bool), Types.CommonDaoError> {
        // no anonymous caller
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller"});
        };
        // check if the neuron already exists
        let mapEntry = neurons.get(caller);
        switch (mapEntry) {
            case (null) {};
            case(?neuron) {
                // neuron already exists
                if(neuron.neuronState == #Dissolved){/* neuron is dissolved, we can re-init it*/}
                else {
                    return #CommonDaoError(#GenericError {message = "Neuron already exists and is not dissolved"});
                };
            };
        };
        // check if the caller deposited enough tokens
        let canisterPrincipal = await idQuick();
        let callerSubAccount : Types.Subaccount =  await Helpers.accountIdentifier(canisterPrincipal, await Helpers.principalToSubaccount(caller));
        let depositAccount = {owner = canisterPrincipal; subaccount = ?callerSubAccount};
        let balance = await _getBalance(depositAccount);
        if(amount > balance){
            // user did not deposit enough :(
            return #CommonDaoError(#GenericError {message = "Not enough tokens deposited"});
        };
        // create the neuron
        let neuron = {
            owner = caller;
            amount = balance;
            dissolveDelay = dissolveDelay;
            neuronState = #Locked;
            createdAt = Time.now();
            dissolvedAt = 0;
            depositSubaccount : Types.Subaccount = callerSubAccount;
            isFollowing = null;
            isFollowedBy = List.nil<Types.Neuron>();
        };
        // add the neuron to the map
        neurons.put(caller, neuron);
        return #Ok(true);
    };

    // Dissolve the neuron. Called once to dissolve the neuron and a second time to get back the funds once the delay is over
    public shared ({caller}) func dissolveNeuron() : async Types.DaoResult<(Bool), Types.CommonDaoError> {
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller not allowed"});
        };
        let mapEntry : ?Types.Neuron = neurons.get(caller);
        switch(mapEntry){
            case(null){
                return #CommonDaoError(#GenericError {message = "User did not create a neuron"})
            };
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
                            isFollowing = neuron.isFollowing;
                            isFollowedBy = neuron.isFollowedBy;
                        };
                        neurons.put(caller, updatedNeuron);
                        return #Ok(true);
                    };
                    case(#Dissolving){
                        if(neuron.createdAt+neuron.dissolveDelay < Time.now()){
                         let res = await _dissolveNeuron(caller, neuron);
                         return #Ok(true);
                        } else {
                            return #CommonDaoError(#GenericError {message = "Neuron is still dissolving"});
                        };
                    };
                    case (#Dissolved){
                        return #CommonDaoError(#GenericError {message = "Neuron is already dissolved"});
                    };
                }
            };
        };
    };

    private func _dissolveNeuron(caller : Principal, neuron : Types.Neuron) : async (Bool) {
           // neuron is ready to be dissolved and funds returned to the user
        let updatedNeuron = {
            owner = neuron.owner;
            amount = neuron.amount;
            dissolveDelay = neuron.dissolveDelay;
            neuronState = #Dissolved;
            createdAt = neuron.createdAt;
            dissolvedAt = neuron.dissolvedAt;
            depositSubaccount = neuron.depositSubaccount;
            isFollowing = neuron.isFollowing;
            isFollowedBy = neuron.isFollowedBy;
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
            fee = ?1000000;
            memo = null;
            created_at_time = null;
        };
        let res = await mbt.icrc1_transfer(transferParameters);
        return true;
    };

    // the voting power of a neuron is equal to its voting power alone + the voting power of all the neurons it is followed by
    public func getNeuronTotalVotingPower(neuron : Types.Neuron) : async Float {
        // get the voting power of the neuron alone
        var finalTotalVotingPower = await getSingleNeuronVotingPower(neuron);
        // get the voting power of the delegates
        let followers = await getAllFollowersAndSubFollowers( List.nil<Types.Neuron>(), neuron.owner);
        let followersIter = List.toIter(followers);
        for (follower in followersIter) {
            let followerVotingPower = await getSingleNeuronVotingPower(follower);
            finalTotalVotingPower := finalTotalVotingPower + followerVotingPower;
        };
        return finalTotalVotingPower;
    };

    // get the voting power of a neuron alone
    public func getSingleNeuronVotingPower(neuron : Types.Neuron) : async Float {
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

    // Neuron Following system functions (à la NNS)
    // The follow graph is an acyclic directed graph. Each neuron has two properties, isFollowing
    // the neuron it is currently following and isFollowedBy a list of neurons that are following it.
    // The voting power of a neuron is equal to the sum of the voting power of the neuron it is followed by. 

    // Follows a neuron
    public shared ({caller}) func follow(willBeFollowed : Principal) : async Types.DaoResult<(Bool), Types.CommonDaoError> {

        // check caller is not anynomous
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller not allowed"});
        };

        let neuronWillFollow = neurons.get(caller);
        if (Option.isNull(neuronWillFollow)) {
            return #CommonDaoError(#GenericError {message = "User did not create a neuron"});
        };

        let neuronToBeFollowed = neurons.get(willBeFollowed);
        if (Option.isNull(neuronToBeFollowed)) {
            return #CommonDaoError(#GenericError {message = "Neuron to be followed does not exist"});
        };

        let wf = Option.unwrap(neuronWillFollow);
        let wbf = Option.unwrap(neuronToBeFollowed);

        // no auto following
        if(Principal.equal(wf.owner,wbf.owner)){
            return #CommonDaoError(#GenericError {message = "Neuron cannot follow itself"});
        };

        // check if the neuron is not already following this neuron
        switch(wf.isFollowing){
            case(null){/*all good*/};
            case(?currentFollowing){
                if(Principal.equal(currentFollowing.owner, wbf.owner)){
                    return #CommonDaoError(#GenericError {message = "Neuron already follows this neuron"});
                };
            };
        };

        // check that resulting graph is acyclic
        let acyclicCheckIsPassed = await checkGraphIsKeptAcyclic(wbf, wf);
        if (not acyclicCheckIsPassed) {
            return #CommonDaoError(#GenericError {message = "Cannot have cycles in the graph"});
        };

        // update the graph of the soon to be ex currently followed neuron, if any
        switch(wf.isFollowing){
            case(null) {
                Debug.print("no following found");
            };
            case(?currentFollowing){
                // Debug.print("We are modifying the current followers of the currently followed neuron :"#currentFollowing.name);
                let cf = neurons.get(currentFollowing.owner);
                if(Option.isNull(cf)){
                    return #CommonDaoError(#GenericError {message = "Something went wrong"});
                };
                let cfd = Option.unwrap(cf);
                let newFollowersList = List.filter<Types.Neuron>(cfd.isFollowedBy, func (neuron : Types.Neuron) : Bool {return Principal.notEqual(neuron.owner, wf.owner);});
                Debug.print("Size of the new followers post filtering "#Nat.toText(Iter.size(List.toIter(newFollowersList))));
                neurons.put(currentFollowing.owner, {
                    owner =  currentFollowing.owner;
                    amount = currentFollowing.amount;
                    dissolveDelay = currentFollowing.dissolveDelay;
                    neuronState = currentFollowing.neuronState;
                    createdAt = currentFollowing.createdAt;
                    dissolvedAt = currentFollowing.dissolvedAt;
                    depositSubaccount = currentFollowing.depositSubaccount;
                    isFollowing = currentFollowing.isFollowing;
                    isFollowedBy = newFollowersList;
                });
            };
        };
        neurons.put(wf.owner, {
            owner = wf.owner;
            amount = wf.amount;
            dissolveDelay = wf.dissolveDelay;
            neuronState = wf.neuronState;
            createdAt = wf.createdAt;
            dissolvedAt = wf.dissolvedAt;
            depositSubaccount = wf.depositSubaccount;
            isFollowing = ?wbf;
            isFollowedBy = wf.isFollowedBy;
        });
        let newFollowersList = List.push<Types.Neuron>(wf, wbf.isFollowedBy);
        neurons.put(wbf.owner, {
            owner = wbf.owner;
            amount = wbf.amount;
            dissolveDelay = wbf.dissolveDelay;
            neuronState = wbf.neuronState;
            createdAt = wbf.createdAt;
            dissolvedAt = wbf.dissolvedAt;
            depositSubaccount = wbf.depositSubaccount;
            isFollowing = wbf.isFollowing;
            isFollowedBy = newFollowersList;
        });
        return #Ok(true);
    };

    // Unfollows a neuron
    public shared ({caller}) func unfollow(willBeUnfollowed : Principal) : async Types.DaoResult<(Bool), Types.CommonDaoError> {
        // check caller is not anonymous
        if(Principal.isAnonymous(caller)) {
            return #CommonDaoError(#GenericError {message = "Anonymous caller not allowed"});
        };
        // get the neuron of the caller
        let neuronToUnfollow = neurons.get(caller);
        if (Option.isNull(neuronToUnfollow)) {
            return #CommonDaoError(#GenericError {message = "User did not create a neuron"});
        };
        // get the neuron to be unfollowed
        let neuronToBeUnfollowed = neurons.get(willBeUnfollowed);
        if (Option.isNull(neuronToBeUnfollowed)) {
            return #CommonDaoError(#GenericError {message = "Neuron to be unfollowed does not exist"});
        };
        
        let wuf = Option.unwrap(neuronToUnfollow);
        let wbuf = Option.unwrap(neuronToBeUnfollowed);

        // check that the neuron is not trying to unfollow itself
        if(Principal.equal(wuf.owner,wbuf.owner)){
            return #CommonDaoError(#GenericError {message = "Neuron cannot unfollow itself"});
        };

        if(Option.isNull(wuf.isFollowing)){
            return #CommonDaoError(#GenericError {message = "You are not following anyone"});
        };

        let wufi = Option.unwrap(wuf.isFollowing);
        if (Principal.notEqual(wufi.owner,wbuf.owner)) {
            return #CommonDaoError(#GenericError {message = "You are trying to unfollow a neuron you are not following"});
        };

        neurons.put(wuf.owner, {
            owner = wuf.owner;
            amount = wuf.amount;
            dissolveDelay = wuf.dissolveDelay;
            neuronState = wuf.neuronState;
            createdAt = wuf.createdAt;
            dissolvedAt = wuf.dissolvedAt;
            depositSubaccount = wuf.depositSubaccount;
            isFollowing = null;
            isFollowedBy = wuf.isFollowedBy;
        });
        let newFollowersList = List.filter<Types.Neuron>(wbuf.isFollowedBy, func (neuron : Types.Neuron) : Bool {return Principal.notEqual(neuron.owner, wuf.owner)});
        neurons.put(wbuf.owner, {
            owner = wbuf.owner;
            amount = wbuf.amount;
            dissolveDelay = wbuf.dissolveDelay;
            neuronState = wbuf.neuronState;
            createdAt = wbuf.createdAt;
            dissolvedAt = wbuf.dissolvedAt;
            depositSubaccount = wbuf.depositSubaccount;
            isFollowing = wbuf.isFollowing;
            isFollowedBy = newFollowersList;
        });
        return #Ok(true);
    };

    // Helper functions

    // Checks that the graph is kept acyclic by getting all the followers and subfollowers of the neuron that will be followed
    // if one of the willFollow account is in the list, then the graph will be cyclic
    public func checkGraphIsKeptAcyclic(willFollow : Types.Neuron, willBeFollowed: Types.Neuron) : async Bool {
        let followersAndSubfollowers = await getAllFollowersAndSubFollowers(List.nil<Types.Neuron>(), willBeFollowed.owner);
        // Debug.print("acyclic check found current followers = "#getAllFollowers(followersAndSubfollowers));
        // check if the new follower is in the list of followers and subfollowers
        let found = List.find(followersAndSubfollowers, func (neuron : Types.Neuron) : Bool {return neuron.owner == willFollow.owner;});
        switch(found){
            case(?something) {
                Debug.print("Found: "#Principal.toText(something.owner));
                return false;
            };
            case(null) {
                return true;
            };
        };
    };

    // Recursively gets all the followers and subfollowers of a neuron
    public func getAllFollowersAndSubFollowers(inter : List.List<Types.Neuron>, neuronOwner: Principal) : async List.List<Types.Neuron> {
        var result : List.List<Types.Neuron> = List.nil<Types.Neuron>();
        let neuron = neurons.get(neuronOwner);
        if (Option.isNull(neuron)) {
            return List.nil<Types.Neuron>();
        };
        let n = Option.unwrap(neuron);
        // Debug.print("Getting all followers and subfollowers of "#n.name#" followers "#getAllFollowers(n.isFollowed));
        result := List.append<Types.Neuron>(inter, n.isFollowedBy);
        let followersIter = List.toIter(n.isFollowedBy);
        if (List.size(n.isFollowedBy)==0) {
            // Debug.print("No followers found, returning inter : "#getAllFollowers(inter));
            return inter;
        };
        for(follower in followersIter) {
            let newResult = await getAllFollowersAndSubFollowers(inter, follower.owner);
            result := List.append<Types.Neuron>(result, newResult);
        };
        return result;
    };

    // Normalize the voting power will first divide the voting power by 100000000 to take into account the MBT decimals and then apply the quadratic voting if enabled
    public func normalizeVotingPower(votingPower : Float) : async Float {
        let normalizedVotingPower = votingPower / 100000000;
        if (quadraticVotingEnabled) {
            return Float.sqrt(normalizedVotingPower);
        };
        return normalizedVotingPower;
    };
    
    // Returns a account derived from the canister's Principal and a subaccount. The subaccount is being derived from the caller's Principal.
    public shared ({ caller }) func getAddress() : async Types.Subaccount {
      let principalCanister = await idQuick();
      let subAcccount = await Helpers.principalToSubaccount(caller);
      return await Helpers.accountIdentifier(principalCanister, subAcccount);
    };

    // Helper function to distinguish between the mainnet and the testnet
    private func getMbtCanisterId() : Text {
        if (Text.equal("mainnet", env)){
            return "db3eq-6iaaa-aaaah-abz6a-cai";
        } else {
            return "renrk-eyaaa-aaaaa-aaada-cai";
        };
    };

    // Helper function to distinguish between the mainnet and the testnet
    private func getWebpageCanisterId() : Text {
        if (Text.equal("mainnet", env)){
            return "6gdk3-2aaaa-aaaap-qa5ma-cai";
        } else {
            return "rno2w-sqaaa-aaaaa-aaacq-cai";
        };
    };

    // Returns the age bonus given an age in months
    public func getAgeBonus(ageInMonths : Float) : async Float {
       if(ageInMonths >= 48){
            return 1.25;
        } else {
            return 0.005*ageInMonths+1;
        };
    };

    // Returns the dissolve bonus given a dissolve delay in months
    public func getDissolveBonus(dissolveDelayInMonths : Float) : async Float {
        if (dissolveDelayInMonths < 6) {
            return 1.0;
        } else if (dissolveDelayInMonths > 6 and dissolveDelayInMonths < 48) {
            return 0.01*dissolveDelayInMonths+0.997;
        } else {
            return 2.0;
        };
    };

    // Returns the amount of months given a number of nanoseconds
    public func nanoSecondsToMonths(nanoSeconds : Int) : async Float {
        return Float.fromInt(nanoSeconds) / 2628000000000000;
    };

    // Getters

    // getter for the minimum amount of voting power required to create a neuron
    public query func getMinimumVotingPower() : async Float {
        return minimumAmountOfVotingPower;
    };

    // getter for the vote acceptance threshold
    public query func getThreshold() : async Float {
        return thresholdAcceptance;
    };

    // getter for the quadratic voting enabled
    public query func getQuadraticVotingEnabled() : async Bool {
        return quadraticVotingEnabled;
    };
    
    /*
    TODO: this is not needed anymore
    public func getLastPassedProposal() : async Text {
        return lastPassedProposal.proposalText;
    };
    */

    // getter for all the proposals
    public query func getAllProposals() : async [Types.Proposal] {
        return Iter.toArray(proposals.vals());
    };

    // getter for a specific proposal
    public query func getProposal(id : Nat64) : async ?Types.Proposal {
        return proposals.get(id)
    };

    // get the balance of a specific account
    public func _getBalance(account : Types.Account) : async Nat {
        // let account = { owner = principal; subaccount = null };
        var res = await mbt.icrc1_balance_of(account);
        // res := res/100000000;
        return res;
    };

    // getter for the dao name. Not really needed but it is nice to have.
    public query func getDaoName() : async Text {
        return daoName;
    };

    // gets the principal of the canister
    public func idQuick() : async Principal {
        return Principal.fromActor(this);
    };

    // get a specific neuron
    public query func getNeuron(caller : Principal) : async ?Types.Neuron {
        return neurons.get(caller);
    };

    // System Upgrade methods

    system func preupgrade() {
      proposalEntries := Iter.toArray(proposals.entries());
      neuronsEntries := Iter.toArray(neurons.entries());
    };

    system func postupgrade() {
      proposalEntries := [];
      neuronsEntries := [];
    };
}