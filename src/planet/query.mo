import Buffer "mo:base/Buffer";
import Debug "mo:base/Debug";
import Types "./types";
import Ulid "mo:ulid/ULID";
import Bool "mo:base/Bool";
import Principal "mo:base/Principal";
import Account "utils/Account";
import ICRC1 "utils/ICRC1";

module {

  type PermissionType = Types.PermissionType;
  // type SubcribeType = Types.SubcribeType;
  type ArticleType = Types.ArticleType;
  type ArticleStatus = Types.ArticleStatus;
  type CommentStatus = Types.CommentStatus;
  type SubcribePrice = Types.SubcribePrice;
  type Subcriber = Types.Subcriber;
  type Category = Types.Category;
  type Article_V1 = Types.Article_V1;
  type Comment = Types.Comment;
  type PayOrder_V1 = Types.PayOrder_V1;
  type AwardOrder_V1 = Types.AwardOrder_V1;

  public type QueryCategory = {
    id : Nat;
    name : Text;
    children : [QueryCategory];
  };

  public type QuerySubcriber = {
    pid : Principal;
    subType : Types.SubcribeType;
    expireTime : Int;
    created : Int;
    isblack : Bool;
  };

  public type OpResult = {
    #Ok : { data : Text };
    #Err : Text;
  };

  public type ArticleStat = {
    total : Nat;
    publicCount : Nat;
    privateCount : Nat;
    subcribeCount : Nat;
    draftCount : Nat;
  };

  public type PlanetBase = {
    owner : Principal;
    writers : [Principal];
    name : Text;
    avatar : Text;
    cover : Text;
    twitter : Text;
    desc : Text;
    lang : Text;
    canindex : Bool;
    created : Int;
    subprices : [Types.SubcribePrice];
    subcriber : Nat;
    subcribers : [QuerySubcriber];
    article : Nat;
    income : Nat64;
    canister : Principal;
    categorys : [QueryCategory];
    url : Text;
  };

  public type PlanetInfo = {
    owner : Principal;
    permission : PermissionType;
    payee : ?Blob;
    name : Text;
    avatar : Text;
    cover : Text;
    twitter : Text;
    desc : Text;
    lang : Text;
    canindex : Bool;
    created : Int;
    writers : [Principal];
    subprices : [Types.SubcribePrice];
    subcriber : Nat;
    subcriber_new : Nat;
    article : Nat;
    income : Nat64;
    canister : Principal;
    categorys : [QueryCategory];
    memory : Nat;
    url : Text;
    last24subcriber : Nat;
    subcribers : [QuerySubcriber];
    articleStat : ArticleStat;
  };

  public type ArticleArgs = {
    id : Text;
    atype : ArticleType;
    title : Text;
    thumb : Text;
    abstract : Text;
    content : Text;
    cate : Nat;
    subcate : Nat;
    status : ArticleStatus;
    allowComment : Bool;
    original : Bool;
    fromurl : Text;
    tags : [Text];
  };

  public type QueryArticle = {
    id : Text;
    atype : ArticleType;
    title : Text;
    thumb : Text;
    author : Principal;
    abstract : Text;
    cate : Nat;
    subcate : Nat;
    created : Int;
    updated : Int;
    toped : Int;
    status : ArticleStatus;
    allowComment : Bool;
    like : Nat;
    unlike : Nat;
    view : Nat64;
    comment : Nat;
    commentTotal : Nat;
    commentNew : Nat;
    original : Bool;
    fromurl : Text;
    tags : [Text];
    copyright : ?Text;
  };

  public type QueryDetailResp = {
    #Ok : {
      article : QueryArticle;
      content : Text;
    };
    #Err : Text;
  };

  public type QuerySort = {
    #TimeDesc;
    #TimeAsc;
  };

  public type QueryArticleReq = {
    page : Nat;
    size : Nat;
    cate : Nat;
    subcate : Nat;
    status : ?ArticleStatus;
    atype : ?ArticleType;
    search : Text;
    sort : QuerySort;
  };

  public type QueryArticleResp = {
    page : Nat;
    total : Int;
    hasmore : Bool;
    stat : ArticleStat;
    data : [QueryArticle];
  };

  public type CommentArgs = {
    aid : Text;
    content : Text;
  };

  public type QueryComment = {
    id : Nat;
    aid : Text;
    pid : Principal;
    content : Text;
    like : Nat;
    status : CommentStatus;
    created : Int;
    reply : ?QueryComment;
  };

  public type QueryCommentReq = {
    page : Nat;
    size : Nat;
    aid : Text;
    pid : ?Principal;
    sort : QuerySort;
  };

  public type QueryCommentResp = {
    page : Nat;
    total : Int;
    hasmore : Bool;
    data : [QueryComment];
  };

  public type QueryCommonReq = {
    page : Nat;
    size : Nat;
    sort : QuerySort;
  };

  public type QueryBlackUserResp = {
    page : Nat;
    total : Int;
    hasmore : Bool;
    data : [Types.BlackUser];
  };

  public type QuerySubcriberResp = {
    page : Nat;
    total : Int;
    hasmore : Bool;
    data : [QuerySubcriber];
  };

  public type QuerySelfSubscriber = {
    data : ?QuerySubcriber;
    isblack : Bool;
  };

  public type QueryCommonSubscriber = {
    data : ?QuerySubcriber;
    issubscriber : Bool;
  };

  public type QueryOrder = {
    id : Nat64;
    from : Principal;
    to : Blob;
    amount : Nat64;
    paytype : Types.PayType;
    source : Text;
    token : Text;
    createdTime : Int;
    amountPaid : Nat64;
    status : Types.PayStatus;
    verifiedTime : ?Int;
    sharedTime : ?Int;
  };

  public type QueryOrderResp = {
    page : Nat;
    total : Int;
    hasmore : Bool;
    data : [QueryOrder];
  };

  public type QueryAward = {
    id : Nat64;
    aid : Text;
    from : Principal;
    token : Text;
    amount : Nat64;
    created : Int;
  };

  public type QueryAwardReq = {
    aid : Text;
    page : Nat;
    size : Nat;
    sort : QuerySort;
  };

  public type QueryAwardResp = {
    page : Nat;
    total : Int;
    hasmore : Bool;
    data : [QueryAward];
  };

  public type TransferArgs = {
    to : Blob;
    memo : Nat64;
    amount : Nat64;
  };

  public type ICRCTransferArgs = {
    token : Text;
    amount : Nat64;
    to : ICRC1.Account;
    memo : ?Blob;
  };

  public func toQueryCategory(cats : [Category]) : [QueryCategory] {
    var ret = Buffer.Buffer<QueryCategory>(0);
    for (cat in cats.vals()) {
      let children = Buffer.Buffer<QueryCategory>(0);
      if (cat.parent == 0) {
        for (c2 in cats.vals()) {
          if (c2.parent == cat.id) {
            children.add({ id = c2.id; name = c2.name; children = [] });
          };
        };
        ret.add({ id = cat.id; name = cat.name; children = Buffer.toArray(children) });
      };
    };
    return Buffer.toArray(ret);
  };

  public func toQuerySubcriber(p : Subcriber, isblack : Bool) : QuerySubcriber {
    {
      pid = p.pid;
      subType = p.subType;
      expireTime = p.expireTime / 1_000_000;
      created = p.created / 1_000_000;
      isblack = isblack;
    };
  };

  public func toQueryOrder(p : PayOrder_V1, to : Blob) : QueryOrder {
    let verifiedTime = switch (p.verifiedTime) {
      case (?v) { ?(v / 1_000_000) };
      case (_) { null };
    };
    let sharedTime = switch (p.sharedTime) {
      case (?v) { ?(v / 1_000_000) };
      case (_) { null };
    };
    {
      id = p.id;
      from = p.from;
      to = to;
      amount = p.amount;
      paytype = p.paytype;
      source = p.source;
      token = p.token;
      createdTime = p.createdTime / 1_000_000;
      amountPaid = p.amountPaid;
      status = p.status;
      verifiedTime = verifiedTime;
      sharedTime = sharedTime;
    };
  };

  public func toQueryArticle(p : Article_V1) : QueryArticle {
    {
      id = Ulid.toText(p.id);
      atype = p.atype;
      author = p.author;
      title = p.title;
      thumb = p.thumb;
      abstract = p.abstract;
      cate = p.cate;
      subcate = p.subcate;
      created = p.created / 1_000_000;
      updated = p.updated / 1_000_000;
      toped = p.toped / 1_000_000;
      status = p.status;
      allowComment = p.allowComment;
      like = p.like;
      unlike = p.unlike;
      view = p.view;
      comment = p.comment;
      commentTotal = p.commentTotal;
      commentNew = p.commentNew;
      original = p.original;
      fromurl = p.fromurl;
      tags = p.tags;
      copyright = p.copyright;
    };
  };

  public func toQueryComment(p : Comment) : QueryComment {
    let reply : ?QueryComment = switch (p.reply) {
      case (?item) {
        ?toQueryComment(item);
      };
      case (_) {
        null;
      };
    };
    {
      id = p.id;
      aid = Ulid.toText(p.aid);
      pid = p.pid;
      content = p.content;
      like = p.like;
      status = p.status;
      created = p.created / 1_000_000;
      reply = reply;
    };
  };

  public func toQueryAward(p : AwardOrder_V1) : QueryAward {
    {
      id = p.id;
      aid = Ulid.toText(p.aid);
      from = p.from;
      token = p.token;
      amount = p.amount;
      created = p.createdTime / 1_000_000;
    };
  };
};
