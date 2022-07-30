
import Types "./types";

module {

  type ArticleType = Types.ArticleType;
  type ArticleStatus = Types.ArticleStatus;
  type CommentStatus = Types.CommentStatus;
  type Category = Types.Category;
  type Article = Types.Article;
  type Comment = Types.Comment;

  public type QueryCategory = {
    id: Nat;
    name: Text;
    children: [QueryCategory];
  };

  public type OpResult = {
    #Ok: { id : Nat; };
    #Err: Text;
  };

  public type ArticleArgs = {
    id: Nat;
    atype: ArticleType;
    title: Text;
    thumb: Text;
    author: Principal;
    abstract: Text;
    content: Text;
    cate: Nat;
    subcate: Nat;
    status: ArticleStatus;
    allowComment: Bool;
    tags: [Text];
  };

  public type QueryArticle = {
    id: Nat;
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
    view: Nat;
    tags: [Text];
    copyright: ?Text;
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
    search: Text;
    sort: QuerySort;
  };

  public type QueryArticleResp = {
    page: Nat;
    total: Int;
    hasmore: Bool;
    data: [QueryArticle];
  };

  public type CommentArgs = {
    content: Text;
    parent: Int;
  };

  public type QueryComment = {
    id: Nat;
    aid: Nat;
    pid: Principal;
    content: Text;
    like: Nat;
    status: CommentStatus;
    created: Int;
    child: ?QueryComment;
  };

  public func toQueryArticle(p: Article): QueryArticle {
    {
      id = p.id;
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
      tags = p.tags;
      copyright = p.copyright;
    };
  };

  public func toQueryComment(p: Comment): QueryComment {
    {
      id = p.id;
      aid = p.aid;
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
      aid = p.aid;
      pid = p.pid;
      content = p.content;
      like = p.like;
      status = p.status;
      created = p.created / 1_000_000;
      child = ?toQueryComment(child);
    };
  };
};