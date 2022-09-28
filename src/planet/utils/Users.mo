module {
  public type PlanetMsg = {
    msg_type : PlanetMsgType;
    data : ?[Nat8];
    user : Principal;
  };
  public type PlanetMsgType = { #add; #remove; #subscribe; #unsubscribe };
  public type Self = actor {
    get_canister : shared query () -> async Principal;
    notify_planet_msg : shared PlanetMsg -> async Bool;
    verify_canister : shared query Principal -> async Bool;
  };
};
