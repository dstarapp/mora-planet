import Principal "mo:base/Principal";
import Time "mo:base/Time";
import Nat32 "mo:base/Nat32";
import Binary "mo:encoding/Binary";

module {
  public type CanisterNodeMap = {
    canister_id : Principal;
    end_node : Nat32;
    start_node : Nat32;
  };
  public type Self = actor {
    allot_canister_list : shared query () -> async [CanisterNodeMap];
    batch_create_canisters : shared Nat32 -> async [CanisterNodeMap];
    get_correlation_canister : shared query Text -> async Principal;
    hdel : shared (Text, Text) -> async ();
    hscan : shared query (Text, Text) -> async Principal;
    hset : shared (Text, Text, [Nat8]) -> async ();
    verify_canister : shared query Principal -> async Bool;
    wallet_balance : shared query () -> async Nat64;
    wallet_receive : shared () -> async ();
  };

  public type LikeActor = actor {
    hdel : shared (Text, Text) -> async Bool;
    hexist : shared query (Text, Text) -> async Bool;
    hget : shared query (Text, Text) -> async ?[Nat8];
    hset : shared (Text, Text, [Nat8]) -> async Bool;
    wallet_balance : shared query () -> async Nat64;
    wallet_receive : shared () -> async ();
  };

  public func hexist(allot : Self, key : Text, filed : Text) : async Bool {
    let pid = await allot.hscan(key, filed);
    let likeActor : LikeActor = actor (Principal.toText(pid));

    return await likeActor.hexist(key, filed);
  };

  public func thumbsup(allot : Self, planet : Principal, aid : Text, caller : Principal) : async Bool {
    let key = "lk_" # Principal.toText(planet) # "_" # aid;
    let field = Principal.toText(caller);
    let ret = await hexist(allot, key, field);
    if (ret) {
      return false;
    };
    let now = Nat32.fromIntWrap(Time.now() / 1_000_000);
    await allot.hset(key, field, Binary.BigEndian.fromNat32(now));
    return true;
  };

  public func cancelThumbsup(allot : Self, planet : Principal, aid : Text, caller : Principal) : async Bool {
    let key = "lk_" # Principal.toText(planet) # "_" # aid;
    let field = Principal.toText(caller);
    let ret = await hexist(allot, key, field);
    if (not ret) {
      return false;
    };
    await allot.hdel(key, field);
    return true;
  };
};
