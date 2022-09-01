import AccountId "mo:accountid/AccountId";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Config "./config";
import Cycles "mo:base/ExperimentalCycles";
import DQueue "./utils/DQueue";
import Debug "mo:base/Debug";
import Hash "mo:base/Hash";
import HashMap "mo:base/HashMap";
import Iter "mo:base/Iter";
import Ledger "./utils/Ledger";
import Nat "mo:base/Nat";
import Nat64 "mo:base/Nat64";
import Prim "mo:prim";
import Principal "mo:base/Principal";
import Query "./query";
import Text "mo:base/Text";
import Time "mo:base/Time";
import Trie "mo:base/Trie";
import TrieMap "mo:base/TrieMap";
import Ulid "mo:ulid/ULID";
import Source "mo:ulid/Source";
import XorShift "mo:rand/XorShift";
import Types "./types";
import Util "./utils/Util";

shared({caller}) actor class Planet(
  _owner : Principal,
  _name: Text,
  _avatar: Text,
  _desc: Text,
  _agree: Ledger.AccountIdentifier,
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

  type PlanetInfo = Query.PlanetInfo;
  type PlanetBase = Query.PlanetBase;
  type OpResult = Query.OpResult;
  type ArticleArgs = Query.ArticleArgs;
  type CommentArgs = Query.CommentArgs;
  type QuerySubcriber = Query.QuerySubcriber;
  type QueryCategory = Query.QueryCategory;
  type QueryArticle = Query.QueryArticle;
  type QueryArticleReq = Query.QueryArticleReq;
  type QueryArticleResp = Query.QueryArticleResp;

  type DQueue<T> = DQueue.DQueue<T>;

  private stable var owner: Principal = _owner;
  private stable var name: Text = _name;
  private stable var avatar: Text = _avatar;
  private stable var twitter: Text = "";
  private stable var desc: Text = _desc;
  private stable var cover: Text = "";
  private stable var totalIncome: Nat64 = 0;
  private stable var payee: ?Ledger.AccountIdentifier = null;
  private stable var argeePayee: ArgeeSharePay = { ratio = 10; to = _agree; remark = "AGREEMENT"};
  private stable var created : Time.Time = Time.now();
  private stable var writers : [Principal] = [];
  private stable var subprices : [SubcribePrice] = [];
  private stable var categorys : [Category] = [];
  private stable var customurl: Text = "";
  private stable var cateindex : Nat = 0;
  private stable var commentindex: Nat = 0;
  private stable var payindex = Prim.intToNat64Wrap(Time.now());
  private stable var articles: DQueue<Article> = DQueue.empty();
  private stable var comments: DQueue<Comment> = DQueue.empty();
  private stable var subcribers: DQueue<Subcriber> = DQueue.empty();
  private stable var allTxs: DQueue<PayOrder> = DQueue.empty();

  // private stable var articleindex: Nat = 0;

  // for sub comment hashmap, need stable
  private var comments_map : TrieMap.TrieMap<Nat, Nat> = TrieMap.TrieMap<Nat, Nat>(Nat.equal, Hash.hash);

  // private var articles : TrieMap.TrieMap<Nat, Article> = TrieMap.TrieMap<Nat, Article>(Nat.equal, Hash.hash);
  // private var allTxs = TrieMap.TrieMap<Nat64, PayOrder>( Nat64.equal, Types.nat64hash);

  // private var test1 : Trie.Trie()
  private let xorr = XorShift.toReader(XorShift.XorShift64(null));
  private let ulse = Source.Source(xorr, 0);
  private let ledger : Ledger.Self = actor(Config.LEDGER_CANISTER_ID);
  private let FEE : Nat64 = 10000;

  system func preupgrade() {
    // subprices_st := subprices.toArray();
  };

  system func postupgrade() {
    // for ( x in subprices_st.vals()) {
    //   subprices.add(x);
    // };
  };

  //return cycles balance
  public query func wallet_balance() : async Nat {
    return Cycles.balance();
  };

  //cycles deposit
  public func wallet_receive() : async { accepted: Nat64 } {
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
  public shared({ caller }) func canisterBalance() : async Ledger.Tokens {
    // assert()
    await ledger.account_balance({ account = accountId(null) })
  };

  // public func testArticleId() : async Text {
  //   return Ulid.toText(ulse.new());
  // };
  // public func queryBlock(height: Nat64) : async [Nat] {
  //   // assert()
  //   // await ledger.query_blocks({ start = height; length = 1});
  //   // let q : DQueue<Nat> = DQueue.empty();
  //   // ignore DQueue.pushBack(q, 1);
  //   // ignore DQueue.pushBack(q, 2);
  //   // ignore DQueue.pushBack(q, 3);
  //   // ignore DQueue.pushBack(q, 4);
  //   // ignore DQueue.pushFront(5, q);
  //   // ignore DQueue.pushFront(6, q);
  //   // ignore DQueue.pushFront(7, q);

  //   // ignore DQueue.remove(q, func (v : Nat) : Bool { v == 3; });

  //   // let x = Buffer.Buffer<Nat>(0);
  //   // for(v1 in DQueue.toReverseIter(q)) {
  //   //   x.add(v1);
  //   // };
  //   // return x.toArray();
  //   return [];
  // };

  public query({caller}) func getPlanetBase(): async PlanetBase {
    var topsubcribers = Buffer.Buffer<QuerySubcriber>(0);
    var count = 0;
    label top for (s in DQueue.toReverseIter(subcribers)) {
      if (count >= 10) {
        break top;
      };
      count := count + 1;
      topsubcribers.add(Query.toQuerySubcriber(s));
    };

    return {
        owner = owner;
        writers = writers;
        name = name;
        avatar = avatar;
        cover = cover;
        twitter = twitter;
        desc = desc;
        created = created / 1_000_000;
        subprices = subprices;
        subcribers = topsubcribers.toArray();
        subcriber = DQueue.size(subcribers);
        article = DQueue.size(articles);
        income = totalIncome;
        canister = Principal.fromActor(this);
        url = customurl;
    };
  };

  public query({caller}) func getPlanetInfo(): async PlanetInfo {
      assert(checkPoster(caller)); //
      return {
          owner = owner;
          permission = permissionType(caller);
          payee = payee;
          name = name;
          avatar = avatar;
          cover = cover;
          twitter = twitter;
          desc = desc;
          created = created / 1_000_000;
          writers = writers;
          subprices = subprices;
          subcriber = DQueue.size(subcribers);
          article = DQueue.size(articles);
          income = totalIncome;
          canister = Principal.fromActor(this);
          memory = Prim.rts_memory_size();
          url = customurl;
      };
  };

  public query({caller}) func adminArticles(req: QueryArticleReq) : async QueryArticleResp {
    assert(checkPoster(caller)); //
    let res = limitAdminArticle(caller, req);
    let data = Buffer.Buffer<QueryArticle>(res.2.size());

    for (x in Array.vals(res.2)) {
      data.add(Query.toQueryArticle(x));
    };

    return {
      page = req.page;
      total = res.0;
      hasmore = res.1;
      data = data.toArray();
    };
  };

  public query({caller}) func adminContent(aid: Text) : async OpResult {
    switch(findArticle(aid)) {
      case(?article) {
        if (not checkOwner(caller)) {
          // only return self created
          if (not Principal.equal(article.author, caller)) {
            return #Err("no permission to read this article!");
          };
        };
        return #Ok({data = article.content});
      };
      case(_) {
        return #Err("article not exist!");
      };
    }
  };

  public query({caller}) func queryArticles(req: QueryArticleReq) : async QueryArticleResp {
    let res = limitQueryArticle(caller, req);
    let data = Buffer.Buffer<QueryArticle>(res.2.size());

    for (x in Array.vals(res.2)) {
      data.add(Query.toQueryArticle(x));
    };

    return {
      page = req.page;
      total = res.0;
      hasmore = res.1;
      data = data.toArray();
    };
  };

  public query({caller}) func queryContent(aid: Text) : async OpResult {
    switch(findArticle(aid)) {
      case(?article) {
        if (article.status == #Draft or article.status == #Private) {
          return #Err("no permission to read this article!");
        };
        let issubcriber = checkSubcriber(caller);
        // subcribe also return list, but not allow read content
        if (not issubcriber and article.status == #Subcribe) {
          return #Err("no permission to read this article!");
        };
        return #Ok({data = article.content});
      };
      case(_) {
        return #Err("article not exist!");
      };
    }
  };

  public shared({ caller }) func setWriters(writer :[Principal]): async Bool {
      assert(caller == owner);
      writers := writers;
      return true;
  };

  public shared({ caller }) func setName(p: Text) : async Bool {
      assert(caller == owner);
      name := p;
      return true;
  };

  public shared({ caller }) func setAvatar(p: Text) : async Bool {
      assert(caller == owner);
      avatar := p;
      return true;
  };

  public shared({ caller }) func setCover(p: Text) : async Bool {
      assert(caller == owner);
      cover := p;
      return true;
  };

  public shared({ caller }) func setDesc(p: Text) : async Bool {
      assert(caller == owner);
      desc := p;
      return true;
  };

  public shared({ caller }) func setPayee(p: Ledger.AccountIdentifier) : async Bool {
      assert(caller == owner);
      switch(payee){
        case(null){
          payee := ?p;
          return true;
        };
        case(_){
          return false;
        };
      }
  };

  // set subcribe prices
  // free => empty prices []
  public shared({ caller }) func setSubPrices(prices: [SubcribePrice]): async Bool {
    assert(caller == owner);
    subprices := prices;
    // old subcribers change to #Permanent or ...
    return true;
  };

  // set all categorys
  public shared({caller}) func setCategorys(cates: [QueryCategory]): async Bool {
    var catemap : HashMap.HashMap<Nat, Bool> = HashMap.HashMap<Nat, Bool>(0, Nat.equal, Hash.hash);
    for(cate in categorys.vals()) {
      catemap.put(cate.id, true);
    };
    categorys := toCategory(cates, catemap, 0);
    return true;
  };

  // owner or writer add article
  public shared({caller}) func addArticle(p : ArticleArgs): async OpResult {
    assert(checkPoster(caller));
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
      created = Time.now();
      var updated = 0;
      var toped = 0;
      var status = p.status;
      var allowComment = p.allowComment;
      var like = 0;
      var unlike = 0;
      var view = 0;
      var tags = p.tags;
      var version = 0;
      var copyright = null;
    };

    ignore DQueue.pushFront(article, articles);

    return #Ok({ data = Ulid.toText(article.id);});
  };

  // owner or writer add article
  public shared({caller}) func updateArticle(p : ArticleArgs): async OpResult {
    assert(checkPoster(caller)); // must check writer
    switch(findArticle(p.id)) {
      case(?article){
        article.title := p.title;
        article.thumb := p.thumb;
        article.abstract := p.abstract;
        article.cate := p.cate;
        article.subcate := p.subcate;
        article.status := p.status;
        article.allowComment := p.allowComment;
        article.version := article.version + 1;
        article.tags := p.tags;
        return #Ok({ data = p.id; });
      };
      case(_){
        return #Err("article id not exist");
      };
    };
    // return #Err("not support");
  };

  public shared({caller}) func topedArticle(aid: Text, toped: Bool): async OpResult {
    assert(checkPoster(caller)); // must check writer
    switch(findArticle(aid)) {
      case(?article){
        if (toped) {
          article.toped := Time.now();
        } else {
          article.toped := 0
        };
        return #Ok({ data = aid; });
      };
      case(_){
        return #Err("article id not exist");
      };
    };
    // return #Err("not support");
  };

  public shared({caller}) func deleteArticle(aid: Text): async Bool {
    assert(checkPoster(caller)); // must check writer
    switch(findArticle(aid)) {
      case(?article){
        switch(article.status) {
          case(#Delete){
            return false;
          };
          case(_){
            article.status := #Delete;
            return true;
          };
        }
      };
      case(_){
        return false;
      };
    };
  };

  public shared({caller}) func copyright(aid : Text): async Bool {
    // assert(checkPoster(caller)); // must check writer
    return false;
  };

  public shared({caller}) func addComment(comment: CommentArgs): async OpResult {
    return #Err("not support");
  };

  // pre subcribe , generate payment order
  public shared({caller}) func preSubcribe(source: Text, price: SubcribePrice): async PayInfo {
    let now = Time.now();
    // add pay order....
    //
    return {
      id = genTxID(now);
      amount = 0;
      to = accountId(?Util.principalToSubAccount(caller));
    };
  };

  // subcribe with block height
  public shared({caller}) func subcribe(payId: Nat64, height: Nat64): async Bool {
    //
    return false;
  };

  private func limitAdminArticle(caller: Principal, req: QueryArticleReq): (Int, Bool, [Article]) {
    if (not checkPoster(caller)) {
      return (0, false, []);
    };
    switch(req.sort) {
      case(#TimeDesc){
        return limitAdminArticleIter(caller, true, req, DQueue.toIter(articles));
      };
      case(_) {
        return limitAdminArticleIter(caller, true, req, DQueue.toReverseIter(articles));
      };
    };
  };

  private func limitQueryArticle(caller: Principal, req: QueryArticleReq): (Int, Bool, [Article]) {
    switch(req.sort) {
      case(#TimeDesc){
        return limitAdminArticleIter(caller, false, req, DQueue.toIter(articles));
      };
      case(_) {
        return limitAdminArticleIter(caller, false, req, DQueue.toReverseIter(articles));
      };
    };
  };

  private func limitAdminArticleIter(caller: Principal, admin: Bool, req: QueryArticleReq, iter: Iter.Iter<Article>): (Int, Bool, [Article]) {
    var data = Buffer.Buffer<Article>(0);
    var total = 0;
    let pagesize = checkPageSize(req.page, req.size);
    let size = pagesize.1;
    var start = (pagesize.0 - 1) * size;
    var issubcriber = false;
    var hasmore = false;

    if (not admin) {
      issubcriber := checkSubcriber(caller);
    };

    Iter.iterate(iter, func(x: Article, idx: Int) {
      if (x.status == #Delete) {
        return;
      };
      if (admin) {
        if (not checkOwner(caller)) {
          // only return self created
          if (not Principal.equal(x.author, caller)) {
            return;
          };
        };
      } else {
        if (x.status == #Draft or x.status == #Private) {
          return;
        };
        // subcribe also return list, but not allow read content
        // if (not issubcriber and req.status == #Subcribe) {
        //   return;
        // }
      };

      if (req.subcate != 0 and req.subcate != x.subcate) {
        return;
      };

      if (req.cate != 0 and req.cate != x.cate) {
        return;
      };

      if (Text.size(req.search) > 0 and not Text.contains(x.title, #text(req.search))) {
        return;
      };

      if (total >= start and total < start + size) {
        data.add(x);
      };
      total := total + 1;
    });
    if (total >= start + size) {
      hasmore := true;
    };
    return (total, hasmore, data.toArray());
  };

  private func checkPageSize(p: Nat, s : Nat): (Int, Int) {
    var page: Int = p;
    if (page < 1) {
      page := 1;
    };
    var size: Int = s;
    if (size > 50) {
      size := 50; // limit max page size
    } else if (size < 1) {
      size := 10;
    };
    return (page, size);
  };


  private func permissionType(caller: Principal): PermissionType {
    if (checkOwner(caller)) {
      return #OWNER;
    };
    if (checkWriter(caller)) {
      return #WRITER;
    };
    return #NONE;
  };

  private func checkOwner(caller: Principal): Bool {
    return Principal.equal(caller, owner);
  };

  private func checkPoster(caller: Principal): Bool {
    if (checkOwner(caller)) {
      return true;
    };
    return checkWriter(caller);
  };

  private func checkWriter(caller: Principal): Bool {
    for (writer in writers.vals()) {
      if (Principal.equal(caller, writer)) {
        return true;
      }
    };
    return false;
  };

  private func checkSubcriber(caller: Principal): Bool {
    if (subprices.size() <= 0) {
      return true;
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

  private func accountId(sa: ?[Nat8]): Ledger.AccountIdentifier {
    Blob.fromArray(AccountId.fromPrincipal(Principal.fromActor(this), sa));
  };

  // share pay to all
  private func sharePay(order: PayOrder): async Bool {
    // compute everyone amount
    let from = Util.principalToSubAccount(order.from);
    let payAmount = order.amount - FEE;
    let payTo : Ledger.TransferArgs = {
      to = accountId(null);
      fee = { e8s = FEE};
      memo = 0;
      amount = { e8s = payAmount};
      from_subaccount = ?from;
      created_at_time = null;
    };
    ignore transfer(payTo);

    // pay to agreement...

    return false;
  };

  private func transfer(args: Ledger.TransferArgs) : async Nat64 {
    let ret = await ledger.transfer(args);
    switch(ret) {
      case (#Ok(height)) {
        return height;
      };
      case(_) {
        return 0;
      }
    };
  };

  private func toCategory(cates : [QueryCategory], catemap : HashMap.HashMap<Nat, Bool>, parent: Nat) : [Category] {
    var allcates = Buffer.Buffer<Category>(0);
    for(cate in cates.vals()) {
      var id : Nat = 0;
      switch(catemap.get(cate.id)) {
        case(?true){
          id := cate.id;
        };
        case(_){
          cateindex := cateindex + 1;
          id := cateindex;
        };
      };
      allcates.add({
        id = id;
        name = cate.name;
        parent = parent;
      });
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

  private func eqUlid(aid : Text) : {id : Ulid.ULID } -> Bool {
    func (x : { id : Ulid.ULID }) : Bool { Ulid.toText(x.id) == aid };
  };

  private func eqId(aid : Nat) : {id : Nat } -> Bool {
    func (x : { id : Nat }) : Bool { x.id == aid };
  };

  private func genTxID(now: Time.Time): Nat64 {
    payindex := payindex + 1;
    return payindex;
  };
};
