import Time "mo:base/Time";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat64 "mo:base/Nat64";
import Ulid "mo:ulid/ULID";
import Order "mo:base/Order";

module {

  public type PermissionType = {
    #OWNER;
    #WRITER;
    #NONE;
  };

  public type SubcribeType = {
    #Free;
    #Day30;
    #Day90;
    #Day180;
    #Day360;
    #Day1000;
    #Permanent;
  };

  public type SubcribePrice = {
    subType : SubcribeType;
    price : Nat;
  };

  public type Subcriber = {
    pid : Principal;
    var subType : SubcribeType;
    var expireTime : Time.Time;
  };

  public type Category = {
    id : Nat;
    name : Text;
    parent : Nat;
  };

  public type ArticleStatus = {
    #Draft;
    #Public;
    #Subcribe;
    #Private;
    #Delete;
  };

  public type ArticleType = {
    #Article;
    #Shortle;
    #Video;
    #Audio;
    #Photos;
  };

  public type Article = {
    id : Ulid.ULID;
    atype : ArticleType;
    var title : Text;
    var thumb : Text;
    author : Principal;
    var abstract : Text;
    var content : Text;
    var cate : Nat;
    var subcate : Nat;
    var created : Int;
    var updated : Int;
    var toped : Int;
    var status : ArticleStatus;
    var allowComment : Bool;
    var like : Nat;
    var unlike : Nat;
    var view : Nat64;
    var comment : Nat;
    var tags : [Text];
    var version : Nat;
    var copyright : ?Text;
  };

  public type CommentStatus = {
    #Invisible;
    #Visible;
  };

  public type Comment = {
    id : Nat;
    aid : Ulid.ULID;
    // article owner
    owner : Principal;
    pid : Principal;
    content : Text;
    created : Int;
    var like : Nat;
    var status : CommentStatus;
    var reply : ?Comment;
  };

  public type PayType = {
    #Price : SubcribePrice;
    // subcribe pay type
    #Verify : Bool;
    // verify pay type
  };

  public type PayStatus = {
    #Unpaid;
    #Paid;
    #Cancel;
  };

  public type PayOrder = {
    id : Nat64;
    from : Principal;
    // real dst account
    amount : Nat64;
    paytype : PayType;
    source : Text;
    // source from which platform
    var amountPaid : Nat64;
    var status : PayStatus;
    var verifiedTime : ?Int;
    var sharedTime : ?Int;
  };

  public type PayInfo = {
    id : Nat64;
    // same as memo
    to : Blob;
    // canister sub account
    amount : Nat64;
    paytype : PayType;
  };

  public type PayResp = {
    #Ok : { invoice : PayInfo };
    #Err : Text;
  };

  public type ArgeeSharePay = {
    ratio : Nat;
    // ratio / 100
    to : Blob;
    remark : Text;
  };

  public type SortArticle = {
    id : Ulid.ULID;
    toped : Int;
    created : Int;
  };

  public type BlackUser = {
    pid : Principal;
    created : Int;
  };

  public func nextType(a : SubcribeType, b : SubcribeType) : SubcribeType {
    let id1 = typeValue(a);
    let id2 = typeValue(b);

    switch (Int.compare(id1, id2)) {
      case (#less) {
        return b;
      };
      case (_) {
        return a;
      };
    };
  };

  public func typeValue(a : SubcribeType) : Int {
    let types = [#Free, #Day30, #Day90, #Day180, #Day360, #Day1000, #Permanent];
    for (i in types.keys()) {
      if (types[i] == a) {
        return i;
      };
    };
    return -1;
  };

  public func typeExpiredTime(a : SubcribeType) : Int {
    switch (a) {
      case (#Free) {
        return 0;
      };
      case (#Day30) {
        return (30 * 86400) * 1_000_000_000;
      };
      case (#Day90) {
        return (90 * 86400) * 1_000_000_000;
      };
      case (#Day180) {
        return (180 * 86400) * 1_000_000_000;
      };
      case (#Day360) {
        return (360 * 86400) * 1_000_000_000;
      };
      case (#Day1000) {
        return (1000 * 86400) * 1_000_000_000;
      };
      case (#Permanent) {
        return (500 * 360 * 86400) * 1_000_000_000;
      };
    };
  };

  public func nat32hash(n : Nat32) : Hash.Hash {
    return n;
  };

  public func nat64hash(n : Nat64) : Hash.Hash {
    return Text.hash(Nat64.toText(n));
  };

  public func compareArticleDesc(a : SortArticle, b : SortArticle) : Order.Order {
    if (a.toped > 0 and b.toped > 0) {
      return Int.compare(b.toped, a.toped);
    } else if (a.toped > 0 and b.toped <= 0) {
      return #less;
    } else if (b.toped > 0 and a.toped <= 0) {
      return #greater;
    };
    return Int.compare(b.created, a.created);
  };

  // 1 6 5 4 3 2 0
  public func beforeCreated(a : Article, b : Article) : Bool {
    if (b.toped > 0) {
      return false;
    };
    return a.created > b.created;
  };
};
