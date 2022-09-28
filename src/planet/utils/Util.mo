import Array "mo:base/Array";
import Blob "mo:base/Blob";
import Buffer "mo:base/Buffer";
import Nat "mo:base/Nat";
import Nat32 "mo:base/Nat32";
import Nat8 "mo:base/Nat8";
import Principal "mo:base/Principal";
import CRC32 "./CRC32";
import SHA224 "./SHA224";
import Account "./Account";
import NatX "mo:numbers/NatX";
import Text "mo:base/Text";

module {
  // Convert principal id to subaccount id.
  public func principalToSubAccount(id : Principal) : [Nat8] {
    let p = Blob.toArray(Principal.toBlob(id));
    Array.tabulate(
      32,
      func(i : Nat) : Nat8 {
        if (i >= p.size() + 1) 0 else if (i == 0)(Nat8.fromNat(p.size())) else (p[i - 1]);
      },
    );
  };

  public func generateInvoiceSubaccount(caller : Principal, payid : Nat64) : [Nat8] {
    let idHash = SHA224.Digest();
    // Length of domain separator
    idHash.write([0x0A]);
    // Domain separator
    idHash.write(Blob.toArray(Text.encodeUtf8("payid")));
    // Counter as Nonce
    let idBytes = Buffer.Buffer<Nat8>(8);
    NatX.encodeNat64(idBytes, payid, #msb);
    idHash.write(idBytes.toArray());
    // Principal of caller
    idHash.write(Blob.toArray(Principal.toBlob(caller)));

    let hashSum = idHash.sum();
    let crc32Bytes = Account.beBytes(CRC32.ofArray(hashSum));
    let buf = Buffer.Buffer<Nat8>(32);
    return Array.append(crc32Bytes, hashSum);
  };
};
