actor {
    var daoName: Text = "ActorDao";

    public query func getDaoName() :async Text {
        return daoName;
    };
}