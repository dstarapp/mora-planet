import Principal "mo:base/Principal";
import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Nat8 "mo:base/Nat8";

module {
  // Convert principal id to subaccount id.
  public func principalToSubAccount(id: Principal) : [Nat8] {
    let p = Blob.toArray(Principal.toBlob(id));
    Array.tabulate(32, func(i : Nat) : Nat8 {
      if (i >= p.size() + 1) 0
      else if (i == 0) (Nat8.fromNat(p.size()))
      else (p[i - 1])
    })
  };
}