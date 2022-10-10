import AccountId "mo:accountid/AccountId";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Cycles "mo:base/ExperimentalCycles";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import RBTree "mo:base/RBTree";
import Source "mo:ulid/Source";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";
import Type "types";
import Types "./types";
import Ulid "mo:ulid/ULID";
import Util "./utils/Util";
import XorShift "mo:rand/XorShift";
import Config "./config";
import DQueue "./utils/DQueue";
import Ledger "./utils/Ledger";
import Query "./query";
import Users "./utils/Users";
import Option "mo:base/Option";

shared ({ caller }) actor class Planet(
  _owner : Principal,
  _name : Text,
  _avatar : Text,
  _desc : Text,
  _agree : Ledger.AccountIdentifier,
) = this {

  type PermissionType = Types.PermissionType;
  type SubcribePrice = Types.SubcribePrice;
  type Category = Types.Category;
  type Article = Types.Article;
  type Comment = Types.Comment;
  type Subcriber = Types.Subcriber;
  type PayInfo = Types.PayInfo;
  type PayOrder = Types.PayOrder;
  type PayType = Types.PayType;
  type ArgeeSharePay = Types.ArgeeSharePay;
  type SortArticle = Types.SortArticle;
  type BlackUser = Types.BlackUser;

  type ArticleStat = Query.ArticleStat;
  type PlanetInfo = Query.PlanetInfo;
  type PlanetBase = Query.PlanetBase;
  type OpResult = Query.OpResult;
  type ArticleArgs = Query.ArticleArgs;
  type CommentArgs = Query.CommentArgs;
  type QuerySubcriber = Query.QuerySubcriber;
  // type QueryCategory = Query.QueryCategory;
  type QueryArticle = Query.QueryArticle;
  type QueryArticleReq = Query.QueryArticleReq;
  type QueryArticleResp = Query.QueryArticleResp;
  type QueryComment = Query.QueryComment;
  type QueryCommentReq = Query.QueryCommentReq;
  type QueryCommentResp = Query.QueryCommentResp;
  type QueryCommonReq = Query.QueryCommonReq;
  type QueryBlackUserResp = Query.QueryBlackUserResp;
  type QuerySubcriberResp = Query.QuerySubcriberResp;
  type QueryDetailResp = Query.QueryDetailResp;

  type DQueue<T> = DQueue.DQueue<T>;

  private stable var owner : Principal = _owner;
  private stable var name : Text = _name;
  private stable var avatar : Text = _avatar;
  private stable var twitter : Text = "";
  private stable var desc : Text = _desc;
  private stable var cover : Text = "";
  private stable var totalIncome : Nat64 = 0;
  private stable var payee : ?Ledger.AccountIdentifier = null;
  private stable var lang : Text = "";
  private stable var argeePayee : ArgeeSharePay = {
    ratio = 1;
    to = _agree;
    remark = "AGREEMENT";
  };
  private stable var created : Time.Time = Time.now();
  private stable var writers : [Principal] = [];
  private stable var subprices : [SubcribePrice] = [];
  private stable var categorys : [Category] = [];
  private stable var customurl : Text = "";
  private stable var cateindex : Nat = 0;
  private stable var commentindex : Nat = 0;
  private stable var payindex = Prim.intToNat64Wrap(Time.now() / 1_000_000);
  private stable var articles : DQueue<Article> = DQueue.empty();
  private stable var comments : DQueue<Comment> = DQueue.empty();
  private stable var subcribers : DQueue<Subcriber> = DQueue.empty();
  private stable var allTxs : DQueue<PayOrder> = DQueue.empty();
  private stable var blacks : DQueue<BlackUser> = DQueue.empty();

  // private stable var articleindex: Nat = 0;
  // private var articles : TrieMap.TrieMap<Nat, Article> = TrieMap.TrieMap<Nat, Article>(Nat.equal, Hash.hash);
  // private var allTxs = TrieMap.TrieMap<Nat64, PayOrder>( Nat64.equal, Types.nat64hash);

  private let blackMap = TrieMap.TrieMap<Principal, Bool>(Principal.equal, Principal.hash);

  private let xorr = XorShift.toReader(XorShift.XorShift64(null));
  private let ulse = Source.Source(xorr, 0);
  private let ledger : Ledger.Self = actor (Config.LEDGER_CANISTER_ID);
  private let userserver : Users.Self = actor (Config.USERS_CANISTER_ID);
  private let FEE : Nat64 = 10000;

  system func preupgrade() {};

  system func postupgrade() {
    for (bl in DQueue.toIter(blacks)) {
      blackMap.put(bl.pid, true);
    };
  };

  //return cycles balance
  public query func wallet_balance() : async Nat {
    return Cycles.balance();
  };

  //cycles deposit
  public func wallet_receive() : async { accepted : Nat64 } {
    let available = Cycles.available();
    let accepted = Cycles.accept(Nat.min(available, 10_000_000));
    { accepted = Nat64.fromNat(accepted) };
  };

  // public func cycles_transfer(
  //   receiver : shared () -> async (),
  //   amount : Nat) : async { refunded : Nat } {
  //     Cycles.add(amount);
  //     await receiver();
  //     { refunded = Cycles.refunded() };
  // };

  // Returns the default account identifier of this canister.
  public query func canisterMemory() : async Nat {
    return Prim.rts_memory_size();
  };

  // Returns the default account identifier of this canister.
  public query func canisterAccount() : async Ledger.AccountIdentifier {
    accountId(null);
  };

  // Returns the balance of this canister.
  public shared ({ caller }) func canisterBalance() : async Ledger.Tokens {
    // assert()
    await ledger.account_balance({ account = accountId(null) });
  };

  // Returns the balance of this canister.
  public shared ({ caller }) func canisterTransfer(args : Query.TransferArgs) : async Bool {
    assert (caller == owner);
    let balance = await ledger.account_balance({ account = accountId(null) });
    if (balance.e8s < (args.amount + FEE)) {
      return false;
    };

    let height = await transfer(
      {
        to = args.to;
        from_subaccount = null;
        memo = args.memo;
        created_at_time = null;
        amount = { e8s = args.amount };
        fee = { e8s = FEE };
      },
    );
    if (height == 0) {
      return false;
    };
    return true;
  };

  // verify owner.
  public query ({ caller }) func verifyOwner(user : ?Principal) : async Bool {
    let id = switch (user) {
      case (?id) id;
      case (_) caller;
    };
    return checkOwner(id);
  };

  // verify writer.
  public query ({ caller }) func verifyWriter(user : ?Principal) : async Bool {
    let id = switch (user) {
      case (?id) id;
      case (_) caller;
    };
    return checkWriter(id);
  };

  // verify writer.
  public query ({ caller }) func verifyOwnerWriter(user : ?Principal) : async Bool {
    let id = switch (user) {
      case (?id) id;
      case (_) caller;
    };
    return checkOwner(id) or checkWriter(id);
  };

  // verify subcriber.
  public query ({ caller }) func verifySubcriber(user : ?Principal) : async Bool {
    let id = switch (user) {
      case (?id) id;
      case (_) caller;
    };
    return checkSubcriber(id);
  };

  public query ({ caller }) func getPlanetBase() : async PlanetBase {
    var topsubcribers = Buffer.Buffer<QuerySubcriber>(0);
    var count = 0;
    label top for (sb in DQueue.toReverseIter(subcribers)) {
      if (count >= 10) {
        break top;
      };
      count := count + 1;
      topsubcribers.add(Query.toQuerySubcriber(sb, isBlackUser(sb.pid)));
    };

    let stat = statAdminArticleIter(caller, false, DQueue.toIter(articles));

    return {
      owner = owner;
      writers = writers;
      name = name;
      avatar = avatar;
      cover = cover;
      twitter = twitter;
      desc = desc;
      lang = lang;
      created = created / 1_000_000;
      subprices = subprices;
      subcribers = topsubcribers.toArray();
      subcriber = DQueue.size(subcribers);
      article = stat.total;
      income = totalIncome;
      canister = Principal.fromActor(this);
      categorys = Query.toQueryCategory(categorys);
      url = customurl;
    };
  };

  public query ({ caller }) func getPlanetInfo() : async PlanetInfo {
    assert (checkPoster(caller));
    //
    var topsubcribers = Buffer.Buffer<QuerySubcriber>(0);
    var count = 0;
    label top for (sb in DQueue.toReverseIter(subcribers)) {
      if (count >= 10) {
        break top;
      };
      count := count + 1;
      topsubcribers.add(Query.toQuerySubcriber(sb, isBlackUser(sb.pid)));
    };

    let stat = statAdminArticleIter(caller, true, DQueue.toIter(articles));

    return {
      owner = owner;
      permission = permissionType(caller);
      payee = payee;
      name = name;
      avatar = avatar;
      cover = cover;
      twitter = twitter;
      desc = desc;
      lang = lang;
      created = created / 1_000_000;
      writers = writers;
      subprices = subprices;
      subcriber = DQueue.size(subcribers);
      article = stat.total;
      income = totalIncome;
      canister = Principal.fromActor(this);
      categorys = Query.toQueryCategory(categorys);
      subcribers = topsubcribers.toArray();
      last24subcriber = calcLast24Count();
      memory = Prim.rts_memory_size();
      url = customurl;
      articleStat = stat;
    };
  };

  public query ({ caller }) func adminBlackUsers(req : QueryCommonReq) : async QueryBlackUserResp {
    assert (checkOwner(caller));
    //
    let res = limitBlackUsers(caller, req);

    return {
      page = req.page;
      total = res.0;
      hasmore = res.1;
      data = res.2;
    };
  };

  public query ({ caller }) func adminSubcribers(req : QueryCommonReq) : async QuerySubcriberResp {
    assert (checkOwner(caller));
    //
    let res = limitSubcribers(caller, req);

    return {
      page = req.page;
      total = res.0;
      hasmore = res.1;
      data = res.2;
    };
  };

  public query ({ caller }) func adminArticles(req : QueryArticleReq) : async QueryArticleResp {
    assert (checkPoster(caller));
    //
    let res = limitAdminArticle(caller, req);
    let stat = statAdminArticleIter(caller, true, DQueue.toIter(articles));

    return {
      page = req.page;
      total = res.0;
      hasmore = res.1;
      data = res.2;
      stat = stat;
    };
  };

  // public query ({ caller }) func adminContent(aid : Text) : async OpResult {
  //   switch (findArticle(aid)) {
  //     case (?article) {
  //       if (not checkOwner(caller)) {
  //         // only return self created
  //         if (not Principal.equal(article.author, caller)) {
  //           return #Err("no permission to read this article!");
  //         };
  //       };
  //       return #Ok({ data = article.content });
  //     };
  //     case (_) {
  //       return #Err("article not exist!");
  //     };
  //   };
  // };

  public query ({ caller }) func adminArticle(aid : Text) : async QueryDetailResp {
    switch (findArticle(aid)) {
      case (?article) {
        if (not checkOwner(caller)) {
          // only return self created
          if (not Principal.equal(article.author, caller)) {
            return #Err("no permission to read this article!");
          };
        };
        return #Ok({ article = Query.toQueryArticle(article); content = article.content });
      };
      case (_) {
        return #Err("article not exist!");
      };
    };
  };

  public query ({ caller }) func queryArticles(req : QueryArticleReq) : async QueryArticleResp {
    let res = limitQueryArticle(caller, req);

    let stat = statAdminArticleIter(caller, false, DQueue.toIter(articles));

    return {
      page = req.page;
      total = res.0;
      hasmore = res.1;
      data = res.2;
      stat = stat;
    };
  };

  // public query ({ caller }) func queryContent(aid : Text) : async OpResult {
  //   switch (findArticle(aid)) {
  //     case (?article) {
  //       if (article.status == #Draft or article.status == #Private) {
  //         return #Err("no permission to read this article!");
  //       };
  //       let issubcriber = checkSubcriber(caller);
  //       // subcribe also return list, but not allow read content
  //       if (not issubcriber and article.status == #Subcribe) {
  //         return #Err("no permission to read this article!");
  //       };
  //       return #Ok({ data = article.content });
  //     };
  //     case (_) {
  //       return #Err("article not exist!");
  //     };
  //   };
  // };

  public query ({ caller }) func queryArticle(aid : Text) : async QueryDetailResp {
    switch (findArticle(aid)) {
      case (?article) {
        if (article.status == #Draft or article.status == #Delete) {
          return #Err("no permission to read this article!");
        };
        if (checkOwner(caller) or Principal.equal(article.author, caller)) {
          return #Ok({ article = Query.toQueryArticle(article); content = article.content });
        };

        if (article.status == #Private) {
          return #Err("no permission to read this article!");
        };
        let issubcriber = checkSubcriber(caller);
        // subcribe also return list, but not allow read content
        if (not issubcriber and article.status == #Subcribe) {
          return #Ok({ article = Query.toQueryArticle(article); content = "" });
        };
        return #Ok({ article = Query.toQueryArticle(article); content = article.content });
      };
      case (_) {
        return #Err("article not exist!");
      };
    };
  };

  public query ({ caller }) func adminComments(req : QueryCommentReq) : async QueryCommentResp {
    let res = limitComment(caller, true, req);
    return {
      page = req.page;
      total = res.0;
      hasmore = res.1;
      data = res.2;
    };
  };

  public query ({ caller }) func queryComments(req : QueryCommentReq) : async QueryCommentResp {
    if (req.aid == "") {
      return { page = req.page; total = 0; hasmore = false; data = [] };
    };

    switch (findArticle(req.aid)) {
      case (?article) {
        var ok = false;
        if (article.status == #Draft or article.status == #Delete) {
          ok := true;
        } else if (article.status == #Private) {
          ok := (not checkOwner(caller) and caller != article.author);
        } else if (article.status == #Subcribe) {
          ok := (not checkOwner(caller) and caller != article.author and not checkSubcriber(caller));
        };
        if ok {
          return { page = req.page; total = 0; hasmore = false; data = [] };
        };
      };
      case (_) {
        return { page = req.page; total = 0; hasmore = false; data = [] };
      };
    };

    let res = limitComment(caller, false, req);
    return {
      page = req.page;
      total = res.0;
      hasmore = res.1;
      data = res.2;
    };
  };

  public query ({ caller }) func getSelfSubcriber() : async Query.QuerySelfSubscriber {
    assert (not Principal.isAnonymous(caller));
    let isblack = isBlackUser(caller);
    let sb = switch (findSubcriber(caller)) {
      case (?sb) {
        ?Query.toQuerySubcriber(sb, isblack);
      };
      case (_) { null };
    };
    return {
      data = sb;
      isblack = isblack;
    };
  };

  public shared ({ caller }) func adminShowComment(cid : Nat, show : Bool) : async Bool {
    switch (findComment(cid)) {
      case (?comment) {
        if (not checkOwner(caller) and caller != comment.owner) {
          return false;
        };
        switch (findArticle(Ulid.toText(comment.aid))) {
          case (?article) {
            if (show) {
              if (comment.status != #Visible) {
                article.comment := article.comment + 1;
              };
              comment.status := #Visible;
            } else {
              if (comment.status != #Invisible) {
                article.comment := article.comment - 1;
              };
              comment.status := #Invisible;
            };
            return true;
          };
          case (_) {};
        };
      };
      case (_) {};
    };
    false;
  };

  public shared ({ caller }) func setOwner(p : Principal) : async Bool {
    assert (caller == owner);
    if (p != owner) {
      // remove old
      ignore userserver.notify_planet_msg({ msg_type = #remove; user = owner; data = null });

      owner := p;
      // add new
      ignore userserver.notify_planet_msg({ msg_type = #add; user = owner; data = null });
    };
    return true;
  };

  public shared ({ caller }) func setWriters(p : [Principal]) : async Bool {
    assert (caller == owner);
    let oldwriters = writers;
    writers := p;
    for (w in oldwriters.vals()) {
      if (not checkWriter(w)) {
        ignore userserver.notify_planet_msg({ msg_type = #remove; user = w; data = null });
      };
    };
    for (w in writers.vals()) {
      ignore userserver.notify_planet_msg({ msg_type = #add; user = w; data = null });
    };
    return true;
  };

  public shared ({ caller }) func setName(p : Text) : async Bool {
    assert (caller == owner);
    name := p;
    return true;
  };

  public shared ({ caller }) func setAvatar(p : Text) : async Bool {
    assert (caller == owner);
    avatar := p;
    return true;
  };

  public shared ({ caller }) func setCover(p : Text) : async Bool {
    assert (caller == owner);
    cover := p;
    return true;
  };

  public shared ({ caller }) func setDesc(p : Text) : async Bool {
    assert (caller == owner);
    desc := p;
    return true;
  };

  public shared ({ caller }) func setTwitter(p : Text) : async Bool {
    assert (caller == owner);
    twitter := p;
    return true;
  };

  public shared ({ caller }) func setLang(p : Text) : async Bool {
    assert (caller == owner);
    lang := Text.map(p, Prim.charToLower);
    return true;
  };

  public shared ({ caller }) func setCustomUrl(p : Text) : async Bool {
    assert (caller == owner);
    customurl := p;
    return true;
  };

  public shared ({ caller }) func addBlackUser(p : Principal) : async Bool {
    assert (caller == owner);
    switch (findBlackUser(p)) {
      case (?user) {
        return false;
      };
      case (_) {
        let user : BlackUser = {
          pid = p;
          created = Time.now();
        };
        blackMap.put(p, true);
        ignore DQueue.pushFront(user, blacks);
      };
    };
    return true;
  };

  public shared ({ caller }) func removeBlackUser(p : Principal) : async Bool {
    assert (caller == owner);
    switch (findBlackUser(p)) {
      case (?user) {
        ignore DQueue.remove(blacks, func(x : { pid : Principal }) : Bool { x.pid == p });
        return true;
      };
      case (_) {};
    };
    return false;
  };

  // public shared ({ caller }) func setPayee(p : Ledger.AccountIdentifier) : async Bool {
  //   assert (caller == owner);
  //   switch (payee) {
  //     case (null) {
  //       payee := ?p;
  //       return true;
  //     };
  //     case (_) {
  //       return false;
  //     };
  //   };
  // };

  // set subcribe prices
  // free => empty prices []
  public shared ({ caller }) func setSubPrices(prices : [Types.SubcribePrice]) : async Bool {
    assert (caller == owner);
    subprices := prices;
    // old subcribers change to #Permanent or ...
    return true;
  };

  // set all categorys
  public shared ({ caller }) func setCategorys(cates : [Query.QueryCategory]) : async Bool {
    assert (caller == owner);
    var catemap : HashMap.HashMap<Nat, Bool> = HashMap.HashMap<Nat, Bool>(0, Nat.equal, Hash.hash);
    for (cate in categorys.vals()) {
      catemap.put(cate.id, true);
    };
    categorys := toCategory(cates, catemap, 0);
    return true;
  };

  // owner or writer add article
  public shared ({ caller }) func addArticle(p : ArticleArgs) : async OpResult {
    assert (checkPoster(caller));
    // articleindex := articleindex + 1;

    let article : Article = {
      id = ulse.new();
      atype = p.atype;
      var title = p.title;
      var thumb = p.thumb;
      author = caller;
      var abstract = p.abstract;
      var content = p.content;
      var cate = p.cate;
      var subcate = p.subcate;
      var created = Time.now();
      var updated = 0;
      var toped = 0;
      var status = p.status;
      var allowComment = p.allowComment;
      var like = 0;
      var unlike = 0;
      var view = 0;
      var comment = 0;
      var commentTotal = 0;
      var tags = p.tags;
      var version = 0;
      var copyright = null;
    };

    ignore DQueue.pushFront(article, articles);

    return #Ok({ data = Ulid.toText(article.id) });
  };

  // owner or writer add article
  public shared ({ caller }) func updateArticle(p : ArticleArgs) : async OpResult {
    assert (checkPoster(caller));
    // must check writer
    switch (findArticle(p.id)) {
      case (?article) {
        let status = article.status;
        article.title := p.title;
        article.thumb := p.thumb;
        article.abstract := p.abstract;
        article.cate := p.cate;
        article.subcate := p.subcate;
        article.status := p.status;
        article.allowComment := p.allowComment;
        article.version := article.version + 1;
        article.tags := p.tags;
        article.content := p.content;
        article.updated := Time.now();
        if (status == #Draft and p.status != #Draft) {
          article.created := Time.now();

          // top must be front.
          ignore DQueue.remove(articles, eqUlid(p.id));
          ignore DQueue.pushFront(article, articles);
        };
        return #Ok({ data = p.id });
      };
      case (_) {
        return #Err("article id not exist");
      };
    };
  };

  public shared ({ caller }) func topedArticle(aid : Text, toped : Bool) : async OpResult {
    assert (checkPoster(caller));
    // must check writer
    switch (findArticle(aid)) {
      case (?article) {
        if (article.status != #Public) {
          return #Err("only public article can be top");
        };
        if (toped) {
          article.toped := Time.now();

          // top must be front.
          ignore DQueue.remove(articles, eqUlid(aid));
          ignore DQueue.pushFront(article, articles);
        } else if (article.toped != 0) {
          article.toped := 0;

          // insert
          ignore DQueue.remove(articles, eqUlid(aid));
          ignore DQueue.insert_before(article, articles, Type.beforeCreated);
        };
        return #Ok({ data = aid });
      };
      case (_) {
        return #Err("article id not exist");
      };
    };
    // return #Err("not support");
  };

  public shared ({ caller }) func deleteArticle(aid : Text) : async Bool {
    assert (checkPoster(caller));
    // must check writer
    switch (findArticle(aid)) {
      case (?article) {
        switch (article.status) {
          case (#Delete) {
            return false;
          };
          case (_) {
            article.status := #Delete;
            return true;
          };
        };
      };
      case (_) {
        return false;
      };
    };
  };

  public shared ({ caller }) func copyright(aid : Text) : async Bool {
    // assert(checkPoster(caller)); // must check writer
    return false;
  };

  public shared ({ caller }) func adminReplyComment(cid : Nat, comment : CommentArgs) : async OpResult {
    switch (findArticle(comment.aid)) {
      case (?article) {
        if (not checkOwner(caller) and caller != article.author) {
          return #Err("no permission to reply this comment!");
        };
        switch (findComment(cid)) {
          case (?parent) {
            commentindex := commentindex + 1;
            let add : Comment = {
              id = commentindex;
              aid = article.id;
              owner = article.author;
              pid = caller;
              content = comment.content;
              created = Time.now();
              var like = 0;
              var status = #Visible;
              var reply = null;
            };
            parent.reply := ?add;
            return #Ok({ data = debug_show (true) });
          };
          case (_) {
            return #Err("comment id not exist");
          };
        };
      };
      case (_) {
        return #Err("article id not exist");
      };
    };
    // return #Err("not support");
  };

  public shared ({ caller }) func addComment(comment : CommentArgs) : async OpResult {
    assert (not Principal.isAnonymous(caller));

    if (isBlackUser(caller)) {
      return #Err("no permission to comment this article!");
    };

    switch (findArticle(comment.aid)) {
      case (?article) {
        if (article.status == #Draft or article.status == #Delete) {
          return #Err("no permission to comment this article!");
        };
        if (not article.allowComment) {
          return #Err("article is not allow comment.");
        };
        if (article.status == #Private) {
          return #Err("no permission to comment this article!");
        };
        let issubcriber = checkSubcriber(caller);
        // subcribe also return list, but not allow read content
        if (not issubcriber and article.status == #Subcribe) {
          return #Err("no permission to comment this article!");
        };
        commentindex := commentindex + 1;
        let add : Comment = {
          id = commentindex;
          aid = article.id;
          owner = article.author;
          pid = caller;
          content = comment.content;
          created = Time.now();
          var like = 0;
          var status = #Invisible;
          var reply = null;
        };
        ignore DQueue.pushFront(add, comments);
        article.commentTotal := article.commentTotal + 1;

        return #Ok({ data = debug_show (add.id) });
      };
      case (_) {
        return #Err("article id not exist");
      };
    };
    return #Err("not support");
  };

  // pre subcribe , generate payment order
  public shared ({ caller }) func preSubscribe(source : Text, price : Types.SubcribePrice) : async Types.PayResp {
    assert (not Principal.isAnonymous(caller));
    if (checkOwner(caller)) {
      return #Err("you are the owner");
    };
    if (isBlackUser(caller)) {
      return #Err("not allow to subscribe");
    };

    let now = Time.now();

    // for test 0.01
    var amount : Nat64 = 1_000_000;
    var sprice : Types.SubcribePrice = price;
    switch (price.subType) {
      case (#Free) {
        if (subprices.size() == 0) {
          amount := 0;
          sprice := { subType = #Free; price = 0 };
        } else {
          return #Err("not allow free subscribe");
        };
      };
      case (_) {
        var has = false;
        var amount_usd = 0;
        label l for (sp in subprices.vals()) {
          if (sp.subType == price.subType) {
            has := true;
            sprice := sp;
            amount_usd := sp.price;
            break l;
          };
        };

        if (not has) {
          return #Err("not find subscribe type: " # debug_show (price.subType));
        }
        //calc amount usd to icp amount
        // test
      };
    };

    // add pay order....
    let order : PayOrder = {
      id = genTxID(now);
      from = caller;
      amount = amount;
      paytype = #Price(sprice);
      source = source;
      token = "ICP";
      var amountPaid = 0;
      var status = #Unpaid;
      var verifiedTime = null;
      var sharedTime = null;
    };

    ignore DQueue.pushFront(order, allTxs);
    //
    return #Ok(
      {
        invoice = {
          id = order.id;
          token = order.token;
          amount = order.amount;
          paytype = order.paytype;
          to = accountId(?Util.generateInvoiceSubaccount(caller, order.id));
        };
      },
    );
  };

  // subcribe with pay ID
  public shared ({ caller }) func subscribe(payId : Nat64) : async Bool {
    assert (not Principal.isAnonymous(caller));
    switch (findPayOrder(payId)) {
      case (?order) {
        if (order.from != caller) {
          return false;
        };
        if (order.verifiedTime != null) {
          return true;
        };
        return await verifyPayorder(order);
      };
      case (_) {};
    };
    //
    return false;
  };

  // unsubscribe
  public shared ({ caller }) func unsubscribe() : async Bool {
    assert (not Principal.isAnonymous(caller));
    if (not checkSubcriber(caller)) {
      return false;
    };

    let res = DQueue.removeOne(subcribers, func(x : { pid : Principal }) : Bool { x.pid == caller });
    switch (res) {
      case (?item) {
        ignore userserver.notify_planet_msg({ msg_type = #unsubscribe; user = caller; data = null });
        return true;
      };
      case (_) {};
    };
    return false;
  };

  // transfer subscribe
  public shared ({ caller }) func transferSubscribe(p : Principal) : async Bool {
    assert (not Principal.isAnonymous(caller));
    if (not checkSubcriber(caller)) {
      return false;
    };
    switch (findSubcriber(caller)) {
      case (?sb) {
        // sb.pid := p;
        let nsb : Subcriber = {
          pid = p;
          created = sb.created;
          var subType = sb.subType;
          var expireTime = sb.expireTime;
        };
        ignore DQueue.pushBack(subcribers, nsb);
        ignore DQueue.removeOne(subcribers, func(x : { pid : Principal }) : Bool { x.pid == caller });

        ignore userserver.notify_planet_msg({ msg_type = #subscribe; user = p; data = null });
        ignore userserver.notify_planet_msg({ msg_type = #unsubscribe; user = caller; data = null });

        return true;
      };
      case (_) {};
    };
    return false;
  };

  private func limitAdminArticle(caller : Principal, req : QueryArticleReq) : (Int, Bool, [QueryArticle]) {
    if (not checkPoster(caller)) {
      return (0, false, []);
    };
    switch (req.sort) {
      case (#TimeDesc) {
        return limitAdminArticleIter(caller, true, req, DQueue.toIter(articles));
      };
      case (_) {
        return limitAdminArticleIter(caller, true, req, DQueue.toReverseIter(articles));
      };
    };
  };

  private func limitQueryArticle(caller : Principal, req : QueryArticleReq) : (Int, Bool, [QueryArticle]) {
    switch (req.sort) {
      case (#TimeDesc) {
        return limitAdminArticleIter(caller, false, req, DQueue.toIter(articles));
      };
      case (_) {
        return limitAdminArticleIter(caller, false, req, DQueue.toReverseIter(articles));
      };
    };
  };

  private func limitComment(caller : Principal, admin : Bool, req : QueryCommentReq) : (Int, Bool, [QueryComment]) {
    switch (req.sort) {
      case (#TimeDesc) {
        return limitAdminCommentIter(caller, admin, req, DQueue.toIter(comments));
      };
      case (_) {
        return limitAdminCommentIter(caller, admin, req, DQueue.toReverseIter(comments));
      };
    };
  };

  private func limitBlackUsers(caller : Principal, req : QueryCommonReq) : (Int, Bool, [BlackUser]) {
    var data = Buffer.Buffer<BlackUser>(0);
    let pagesize = checkPageSize(req.page, req.size);
    let size = pagesize.1;
    var start = (pagesize.0 - 1) * size;
    var hasmore = false;
    var total = 0;

    var iter : Iter.Iter<BlackUser> = DQueue.toIter(blacks);
    if (req.sort == #TimeAsc) {
      iter := DQueue.toReverseIter(blacks);
    };

    Iter.iterate(
      iter,
      func(x : BlackUser, idx : Int) {
        if (total >= start and total < start + size) {
          data.add(x);
        };
        total := total + 1;
      },
    );
    if (total >= start + size) {
      hasmore := true;
    };
    return (total, hasmore, data.toArray());
  };

  private func limitSubcribers(caller : Principal, req : QueryCommonReq) : (Int, Bool, [QuerySubcriber]) {
    var data = Buffer.Buffer<QuerySubcriber>(0);
    let pagesize = checkPageSize(req.page, req.size);
    let size = pagesize.1;
    var start = (pagesize.0 - 1) * size;
    var hasmore = false;
    var total = 0;

    var iter : Iter.Iter<Subcriber> = DQueue.toIter(subcribers);
    if (req.sort == #TimeAsc) {
      iter := DQueue.toReverseIter(subcribers);
    };

    Iter.iterate(
      iter,
      func(x : Subcriber, idx : Int) {
        if (total >= start and total < start + size) {
          data.add(Query.toQuerySubcriber(x, isBlackUser(x.pid)));
        };
        total := total + 1;
      },
    );
    if (total >= start + size) {
      hasmore := true;
    };
    return (total, hasmore, data.toArray());
  };

  private func statAdminArticleIter(caller : Principal, admin : Bool, iter : Iter.Iter<Article>) : ArticleStat {
    var total = 0;
    var subcribe = 0;
    var pub = 0;
    var pri = 0;
    var draft = 0;
    var issubcriber = false;

    if (not admin) {
      issubcriber := checkSubcriber(caller);
    };

    Iter.iterate(
      iter,
      func(x : Article, idx : Int) {
        if (x.status == #Delete) {
          return;
        };
        if (admin or x.status == #Private) {
          if (not checkOwner(caller)) {
            // only return self created
            if (not Principal.equal(x.author, caller)) {
              return;
            };
          };
        } else {
          if (x.status == #Draft) {
            return;
          };
        };
        switch (x.status) {
          case (#Private) {
            pri := pri + 1;
          };
          case (#Subcribe) {
            subcribe := subcribe + 1;
          };
          case (#Public) {
            pub := pub + 1;
          };
          case (#Draft) {
            draft := draft + 1;
          };
          case (_) {};
        };
        if (x.status != #Draft) {
          total := total + 1;
        };
      },
    );

    return {
      total = total;
      publicCount = pub;
      privateCount = pri;
      subcribeCount = subcribe;
      draftCount = draft;
    };
  };

  private func limitAdminArticleIter(caller : Principal, admin : Bool, req : QueryArticleReq, iter : Iter.Iter<Article>) : (Int, Bool, [QueryArticle]) {
    var data = Buffer.Buffer<QueryArticle>(0);
    let pagesize = checkPageSize(req.page, req.size);
    let size = pagesize.1;
    var start = (pagesize.0 - 1) * size;
    var hasmore = false;

    // var issubcriber = false;
    // if (not admin) {
    //   issubcriber := checkSubcriber(caller);
    // };
    let topvalue = limitTopArticleIter(caller, admin, req, data);
    var total = topvalue.0;
    // Debug.print("total top " # debug_show(data.toArray()));

    Iter.iterate(
      iter,
      func(x : Article, idx : Int) {
        // Debug.print("article id: " # Ulid.toText(x.id));
        if (x.toped != 0) {
          return;
        };
        if (not checkQuery(caller, x, admin, req)) {
          return;
        };
        if (total >= start and total < start + size) {
          data.add(Query.toQueryArticle(x));
        };
        total := total + 1;
      },
    );
    if (total >= start + size) {
      hasmore := true;
    };
    return (total, hasmore, data.toArray());
  };

  private func limitTopArticleIter(caller : Principal, admin : Bool, req : QueryArticleReq, data : Buffer.Buffer<QueryArticle>) : (Int, Bool) {
    var total = 0;
    let pagesize = checkPageSize(req.page, req.size);
    let size = pagesize.1;
    var start = (pagesize.0 - 1) * size;
    var hasmore = false;

    Iter.iterate(
      DQueue.toIter(articles),
      func(x : Article, idx : Int) {
        if (x.toped == 0) {
          return;
        };
        if (not checkQuery(caller, x, admin, req)) {
          return;
        };
        if (total >= start and total < start + size) {
          data.add(Query.toQueryArticle(x));
        };
        total := total + 1;
      },
    );

    if (total >= start + size) {
      hasmore := true;
    };
    return (total, hasmore);
  };

  private func limitAdminCommentIter(caller : Principal, admin : Bool, req : QueryCommentReq, iter : Iter.Iter<Comment>) : (Int, Bool, [QueryComment]) {
    var data = Buffer.Buffer<QueryComment>(0);
    let pagesize = checkPageSize(req.page, req.size);
    let size = pagesize.1;
    var start = (pagesize.0 - 1) * size;
    var hasmore = false;
    var total = 0;

    Iter.iterate(
      iter,
      func(x : Comment, idx : Int) {
        // Debug.print("article id: " # Ulid.toText(x.id));
        if (admin) {
          if (not checkOwner(caller) and caller != x.owner and caller != x.pid) {
            return;
          };
        } else {
          if (x.status == #Invisible) {
            return;
          };
        };
        switch (req.pid) {
          case (?author) {
            if (author != x.pid) {
              return;
            };
          };
          case (_) {};
        };
        if (req.aid != "" and Ulid.toText(x.aid) != req.aid) {
          return;
        };
        if (total >= start and total < start + size) {
          data.add(Query.toQueryComment(x));
        };
        total := total + 1;
      },
    );
    if (total >= start + size) {
      hasmore := true;
    };
    return (total, hasmore, data.toArray());
  };

  private func checkQuery(caller : Principal, x : Article, admin : Bool, req : QueryArticleReq) : Bool {
    if (admin) {
      if (not checkOwner(caller)) {
        // only return self created
        if (not Principal.equal(x.author, caller)) {
          return false;
        };
      };
      if (x.status == #Draft) {
        switch (req.status) {
          case (?#Draft) {
            return true;
          };
          case (_) {};
        };
        return false;
      };
      if (x.status == #Delete) {
        switch (req.status) {
          case (?#Delete) {
            return true;
          };
          case (_) {};
        };
        return false;
      };
    } else {
      switch (x.status) {
        case (#Delete) { return false };
        case (#Draft) { return false };
        case (#Private) {
          if (not checkOwner(caller)) {
            // only return self created
            if (not Principal.equal(x.author, caller)) {
              return false;
            };
          };
        };
        case (_) {};
      };
      // subcribe also return list, but not allow read content
      // if (not issubcriber and req.status == #Subcribe) {
      //   return;
      // }
    };

    if (req.subcate != 0 and req.subcate != x.subcate) {
      return false;
    };

    if (req.cate != 0 and req.cate != x.cate) {
      return false;
    };

    switch (req.atype) {
      case (?atype) {
        if (x.atype != atype) {
          return false;
        };
      };
      case (_) {};
    };

    switch (req.status) {
      case (?status) {
        if (x.status != status) {
          return false;
        };
      };
      case (_) {};
    };

    if (Text.size(req.search) > 0 and not Text.contains(x.title, #text(req.search))) {
      return false;
    };
    return true;
  };

  private func checkPageSize(p : Nat, s : Nat) : (Int, Int) {
    var page : Int = p;
    if (page < 1) {
      page := 1;
    };
    var size : Int = s;
    if (size > 50) {
      size := 50;
      // limit max page size
    } else if (size < 1) {
      size := 10;
    };
    return (page, size);
  };

  private func permissionType(caller : Principal) : PermissionType {
    if (checkOwner(caller)) {
      return #OWNER;
    };
    if (checkWriter(caller)) {
      return #WRITER;
    };
    return #NONE;
  };

  private func checkOwner(caller : Principal) : Bool {
    return Principal.equal(caller, owner);
  };

  private func checkPoster(caller : Principal) : Bool {
    if (checkOwner(caller)) {
      return true;
    };
    return checkWriter(caller);
  };

  private func checkWriter(caller : Principal) : Bool {
    for (writer in writers.vals()) {
      if (Principal.equal(caller, writer)) {
        return true;
      };
    };
    return false;
  };

  private func checkSubcriber(caller : Principal) : Bool {
    // if (subprices.size() <= 0) {
    //   return true;
    // };
    switch (findBlackUser(caller)) {
      case (?user) {
        return false;
      };
      case (_) {};
    };
    let now = Time.now() / 1_000_000;
    for (item in DQueue.toIter(subcribers)) {
      if (Principal.equal(caller, item.pid)) {
        if (item.subType == #Free or item.expireTime > now) {
          return true;
        };
      };
    };
    false;
  };

  private func accountId(sa : ?[Nat8]) : Ledger.AccountIdentifier {
    Blob.fromArray(AccountId.fromPrincipal(Principal.fromActor(this), sa));
  };

  private func verifyPayorder(order : PayOrder) : async Bool {
    switch (order.paytype) {
      case (#Price(price)) {
        if (price.subType == #Free or order.amount == 0) {
          order.status := #Paid;
          order.verifiedTime := ?Time.now();
          order.sharedTime := ?Time.now();

          await userSubscribe(order.from, price);
          return true;
        };
      };
      case (_) {};
    };

    let to = accountId(?Util.generateInvoiceSubaccount(order.from, order.id));
    let balance = await ledger.account_balance({ account = to });

    if (balance.e8s < order.amount) {
      return false;
    };

    totalIncome := totalIncome + balance.e8s;
    order.status := #Paid;
    order.amountPaid := balance.e8s;
    order.verifiedTime := ?Time.now();
    switch (order.paytype) {
      case (#Price(price)) {
        // user subcribe
        await userSubscribe(order.from, price);

        ignore sharePay(order);
      };
      case (_) {};
    };
    return true;
  };

  private func userSubscribe(user : Principal, price : SubcribePrice) : async () {
    switch (findSubcriber(user)) {
      case (?sb) {
        sb.subType := Types.nextType(sb.subType, price.subType);
        if (sb.expireTime < Time.now()) {
          sb.expireTime := Time.now();
        } else {
          sb.expireTime := sb.expireTime + Types.typeExpiredTime(sb.subType);
        };
      };
      case (_) {
        ignore DQueue.pushBack(
          subcribers,
          {
            pid = user;
            created = Time.now();
            var subType = price.subType;
            var expireTime = Time.now() + Types.typeExpiredTime(price.subType);
          },
        );
      };
    };

    ignore userserver.notify_planet_msg({ msg_type = #subscribe; user = user; data = null });
  };

  // share pay to all
  private func sharePay(order : PayOrder) : async Bool {
    // compute everyone amount
    if (order.sharedTime != null) {
      return false;
    };

    let from = Util.generateInvoiceSubaccount(order.from, order.id);
    var amount = order.amountPaid;
    var sharedAmount = (amount * Nat64.fromNat(argeePayee.ratio)) / 100;
    if (amount < FEE) {
      order.sharedTime := ?Time.now();
      return true;
    };
    amount := amount - FEE;
    if (amount < sharedAmount) {
      sharedAmount := amount;
    };
    // pay to agreement...
    let sharedT : Ledger.TransferArgs = {
      to = argeePayee.to;
      fee = { e8s = FEE };
      memo = 0;
      amount = { e8s = sharedAmount };
      from_subaccount = ?from;
      created_at_time = null;
    };

    let r0 = await transfer(sharedT);
    if (r0 == 0) {
      return false;
    };

    amount := amount - sharedAmount;
    if (amount < FEE) {
      order.sharedTime := ?Time.now();
      return true;
    };
    let payAmount = amount - FEE;
    let payTo : Ledger.TransferArgs = {
      to = accountId(null);
      fee = { e8s = FEE };
      memo = 0;
      amount = { e8s = payAmount };
      from_subaccount = ?from;
      created_at_time = null;
    };

    let r1 = await transfer(payTo);
    if (r1 == 0) {
      return false;
    };

    order.sharedTime := ?Time.now();
    return true;
  };

  private func transfer(args : Ledger.TransferArgs) : async Nat64 {
    let ret = await ledger.transfer(args);
    switch (ret) {
      case (#Ok(height)) {
        return height;
      };
      case (_) {
        return 0;
      };
    };
  };

  private func toCategory(cates : [Query.QueryCategory], catemap : HashMap.HashMap<Nat, Bool>, parent : Nat) : [Category] {
    var allcates = Buffer.Buffer<Category>(0);
    for (cate in cates.vals()) {
      var id : Nat = 0;
      switch (catemap.get(cate.id)) {
        case (?true) {
          id := cate.id;
        };
        case (_) {
          cateindex := cateindex + 1;
          id := cateindex;
        };
      };
      allcates.add({ id = id; name = cate.name; parent = parent });
      catemap.put(id, true);
      let children = toCategory(cate.children, catemap, id);
      for (child in children.vals()) {
        allcates.add(child);
      };
    };
    return allcates.toArray();
  };

  private func findArticle(aid : Text) : ?Article {
    DQueue.find(articles, eqUlid(aid));
  };

  private func findComment(cid : Nat) : ?Comment {
    DQueue.find(comments, eqId(cid));
  };

  private func findPayOrder(oid : Nat64) : ?PayOrder {
    DQueue.find(allTxs, func(x : { id : Nat64 }) : Bool { x.id == oid });
  };

  private func findSubcriber(p : Principal) : ?Subcriber {
    DQueue.find(subcribers, func(x : { pid : Principal }) : Bool { x.pid == p });
  };

  private func findBlackUser(p : Principal) : ?BlackUser {
    DQueue.find(blacks, func(x : { pid : Principal }) : Bool { x.pid == p });
  };

  private func eqUlid(aid : Text) : { id : Ulid.ULID } -> Bool {
    func(x : { id : Ulid.ULID }) : Bool { Ulid.toText(x.id) == aid };
  };

  private func eqId(aid : Nat) : { id : Nat } -> Bool {
    func(x : { id : Nat }) : Bool { x.id == aid };
  };

  private func genTxID(now : Time.Time) : Nat64 {
    payindex := payindex + 1;
    return payindex;
  };

  private func calcLast24Count() : Nat {
    let n24 = Time.now() - 24 * 3600 * 1_000_000_000;
    var count = 0;

    for (sb in DQueue.toIter(subcribers)) {
      if (sb.created > n24) {
        count := count + 1;
      };
    };

    return count;
  };

  private func isBlackUser(user : Principal) : Bool {
    return Option.isSome(blackMap.get(user));
  };
};
