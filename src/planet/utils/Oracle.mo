module {
  public type DataResponse = {
    sid : SeriesId;
    decimals : Nat;
    data : (Timestamp, Nat);
    name : Text;
  };
  public type SeriesId = Nat;
  public type Timestamp = Nat;

  public type ICOracle = actor {
    get : shared query (SeriesId, ?Timestamp) -> async ?DataResponse;
  };

  public type IcpUsdRate = {
    decimals : Nat;
    rate : Nat;
  };

  public func getIcp2Usd(oracle : ICOracle) : async ?IcpUsdRate {
    let icp_sid : SeriesId = 2;
    let resp = await oracle.get(icp_sid, null);
    switch (resp) {
      case (?rs) {
        return ?{
          decimals = rs.decimals;
          rate = rs.data.1;
        };
      };
      case (_) {
        return null;
      };
    };
  };
};
