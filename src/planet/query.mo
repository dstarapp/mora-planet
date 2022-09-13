
import Ulid "mo:ulid/ULID";
import Types "./types";
import Buffer "mo:base/Buffer";

module {

  type PermissionType = Types.PermissionType;
  // type SubcribeType = Types.SubcribeType;
  type ArticleType = Types.ArticleType;
  type ArticleStatus = Types.ArticleStatus;
  type CommentStatus = Types.CommentStatus;
  type SubcribePrice = Types.SubcribePrice;
  type Subcriber = Types.Subcriber;
  type Category = Types.Category;
  type Article = Types.Article;
  type Comment = Types.Comment;

  public type QueryCategory = {
    id: Nat;
    name: Text;
    children: [QueryCategory];
  };

  public type QuerySubcriber = {
    pid : Principal;
    subType: Types.SubcribeType;
    expireTime: Int;
  };

  public type OpResult = {
    #Ok: { data : Text; };
    #Err: Text;
  };

  public type ArticleStat = {
    total: Nat;
    publicCount: Nat;
    privateCount: Nat;
    subcribeCount: Nat;
    draftCount: Nat;
  };

  public type PlanetBase = {
    owner: Principal;
    writers: [Principal];
    name: Text;
    avatar: Text;
    cover: Text;
    twitter: Text;
    desc: Text;
    created: Int;
    subprices: [Types.SubcribePrice];
    subcriber: Nat;
    subcribers: [QuerySubcriber];
    article: Nat;
    income: Nat64;
    canister: Principal;
    url: Text;
  };

  public type PlanetInfo = {
    owner: Principal;
    permission: PermissionType;
    payee: ?Blob;
    name: Text;
    avatar: Text;
    cover: Text;
    twitter: Text;
    desc: Text;
    created: Int;
    writers: [Principal];
    subprices: [Types.SubcribePrice];
    subcriber: Nat;
    article: Nat;
    income: Nat64;
    canister: Principal;
    categorys: [QueryCategory];
    memory: Nat;
    url: Text;
    last24subcriber: Nat;
    subcribers: [QuerySubcriber];
    articleStat: ArticleStat;
  };

  public type ArticleArgs = {
    id: Text;
    atype: ArticleType;
    title: Text;
    thumb: Text;
    abstract: Text;
    content: Text;
    cate: Nat;
    subcate: Nat;
    status: ArticleStatus;
    allowComment: Bool;
    tags: [Text];
  };

  public type QueryArticle = {
    id: Text;
    atype: ArticleType;
    title: Text;
    thumb: Text;
    author: Principal;
    abstract: Text;
    cate: Nat;
    subcate: Nat;
    created: Int;
    updated: Int;
    toped: Int;
    status: ArticleStatus;
    allowComment: Bool;
    like: Nat;
    unlike: Nat;
    view: Nat64;
    comment: Nat;
    tags: [Text];
    copyright: ?Text;
  };

  public type QueryDetailResp = {
    #Ok: {
      article: QueryArticle;
      content: Text;
    };
    #Err: Text;
  };

  public type QuerySort = {
    #TimeDesc;
    #TimeAsc;
  };

  public type QueryArticleReq = {
    page: Nat;
    size: Nat;
    cate: Nat;
    subcate: Nat;
    status: ?ArticleStatus;
    atype: ?ArticleType;
    search: Text;
    sort: QuerySort;
  };

  public type QueryArticleResp = {
    page: Nat;
    total: Int;
    hasmore: Bool;
    stat: ArticleStat;
    data: [QueryArticle];
  };

  public type CommentArgs = {
    content: Text;
    parent: Int;
  };

  public type QueryComment = {
    id: Nat;
    aid: Text;
    pid: Principal;
    content: Text;
    like: Nat;
    status: CommentStatus;
    created: Int;
    child: ?QueryComment;
  };

  public func toQueryCategory(cats : [Category]): [QueryCategory] {
    var ret = Buffer.Buffer<QueryCategory>(0);
    for (cat in cats.vals()) {
      let children = Buffer.Buffer<QueryCategory>(0);
      if (cat.parent == 0) {
        for (c2 in cats.vals()) {
          if (c2.parent == cat.id) {
            children.add({
              id = c2.id;
              name = c2.name;
              children = [];
            })
          };
        };
        ret.add({
          id = cat.id;
          name = cat.name;
          children = children.toArray();
        });
      };
    };
    return ret.toArray();
  };

  public func toQuerySubcriber(p: Subcriber): QuerySubcriber {
    {
      pid = p.pid;
      subType = p.subType;
      expireTime = p.expireTime / 1_000_000;
    }
  };

  public func toQueryArticle(p: Article): QueryArticle {
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
      tags = p.tags;
      copyright = p.copyright;
    };
  };

  public func toQueryComment(p: Comment): QueryComment {
    {
      id = p.id;
      aid = Ulid.toText(p.aid);
      pid = p.pid;
      content = p.content;
      like = p.like;
      status = p.status;
      created = p.created / 1_000_000;
      child = null;
    };
  };

  public func toQueryCommentWith(p: Comment, child: Comment): QueryComment {
    {
      id = p.id;
      aid = Ulid.toText(p.aid);
      pid = p.pid;
      content = p.content;
      like = p.like;
      status = p.status;
      created = p.created / 1_000_000;
      child = ?toQueryComment(child);
    };
  };
};