
import Time "mo:base/Time";
import Int "mo:base/Int";
import Buffer "mo:base/Buffer";
import Hash "mo:base/Hash";
import Text "mo:base/Text";
import Nat64 "mo:base/Nat64";

module {

  public type PlanetInfo = {
    owner: Principal;
    name: Text;
    avatar: Text;
    twitter: Text;
    desc: Text;
    created: Time.Time;
    writers: [Principal];
    subprices: [SubcribePrice];
    subcriber: Nat;
    article: Nat;
    canister: Principal;
    url: Text;
  };

  public type PlanetBase = {
    name: Text;
    avatar: Text;
    twitter: Text;
    desc: Text;
    created: Time.Time;
    subprices: [SubcribePrice];
    subcriber: Nat;
    article: Nat;
    canister: Principal;
    url: Text;
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
    subType: SubcribeType;
    price: Nat;
  };

  public type Subcriber = {
    pid : Principal;
    var subType: SubcribeType;
    var expireTime: Time.Time;
  };

  public type Category = {
    id: Nat;
    name: Text;
    parent: Nat;
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
    id: Nat;
    atype: ArticleType;
    var title: Text;
    var thumb: Text;
    author: Principal;
    var abstract: Text;
    var content: Text;
    var cate: Nat;
    var subcate: Nat;
    created: Int;
    var updated: Int;
    var toped: Int;
    var status: ArticleStatus;
    var allowComment: Bool;
    var like: Nat;
    var unlike: Nat;
    var view: Nat;
    var tags: [Text];
    var version: Nat;
    var copyright: ?Text;
  };

  public type CommentStatus = {
    #Invisible;
    #Visible;
  };

  public type Comment = {
    id: Nat;
    aid: Nat;
    pid: Principal;
    content: Text;
    var like: Nat;
    var status: CommentStatus;
    created: Int;
    parent: Nat;
  };

  public type PayType = {
    #Price: SubcribePrice; // subcribe pay type
    #Verify: Bool;         // verify pay type
  };

  public type PayOrder = {
    id: Nat64;
    from: Principal;
    to: Blob;
    amount: Nat64;
    var block: Nat64;
    paytype: PayType;
    source: Text; // source from which platform
  };

  public type PayInfo = {
    id: Nat64; // same as memo
    to: Blob;
    amount: Nat64;
  };

  public type ArgeeSharePay = {
    ratio : Nat; // ratio / 100
    to: Blob;
    remark: Text;
  };

  public func nextType(a: SubcribeType, b: SubcribeType): SubcribeType {
    let id1 = typeValue(a);
    let id2 = typeValue(b);

    switch(Int.compare(id1, id2)) {
      case(#less) {
        return b;
      };
      case(_) {
        return a;
      };
    };
  };

  public func typeValue(a: SubcribeType): Int {
      let types = [#Free, #Day30, #Day90, #Day180, #Day360, #Day1000, #Permanent];
      for ( i in types.keys()) {
        if (types[i] == a) {
          return i;
        }
      };
      return -1;
  };

  public func nat32hash(n: Nat32) : Hash.Hash {
    return n;
  };

  public func nat64hash(n: Nat64) : Hash.Hash {
    return Text.hash(Nat64.toText(n));
  };

}